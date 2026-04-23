# eMoney Handover — Complete Package (v1)

**Audience**: Wave Technology — Infrastructure, DevOps, Security, and Operations teams
**Authors**: Huy Nguyen Duc (AWS infrastructure) + DK Nguyen (app stack + pipeline operations)
**Organization**: Trustify Technology (contracted through Zeyalabs)
**Version**: v1 — 2026-04-23
**Source documents** (canonical, kept separately in the repo):
- [HANDOVER_INFRA.md](HANDOVER_INFRA.md) — infrastructure spec (Huy)
- [HANDOVER_APP.md](HANDOVER_APP.md) — app stack operations (DK)
- [emoney.drawio.png](emoney.drawio.png) — architecture diagram (repo root)

> This is the **unified delivery package** for Wave. It combines the infrastructure spec and the app-operations spec into a single reviewable document. The source docs remain canonical — if either updates, regenerate `v2` of this file from the new sources. Do **not** edit this file directly; edit the source docs and regenerate.

---

## TL;DR for leadership (30-second read)

- **Wave hosts eMoney on Wave's own AWS account.** Trustify operates the app stack on top via granted IAM access. This is the "landlord/operator" model Rita approved on 2026-04-22.
- **Three independent stacks inside one VPC**: Dashboard (static site via ALB+S3), n8n Worker (EC2+EFS+RDS), Events pipeline (n8n→SQS→Lambda→RDS). Clean failure isolation.
- **All traffic stays inside the VPC** — no public internet exposure. VPC Endpoints for S3, SQS, Bedrock, Secrets Manager. No port 22. ALB is internal-only; Wave picks the access path (corporate CIDR / Client VPN / Site-to-site VPN).
- **AI extraction** via AWS Bedrock (Claude Opus 4.7). Replaces the Gemini API we used during the PoC phase.
- **Estimated cost**: ~$112/mo excluding Bedrock usage (Bedrock scales with email volume, typically $20–100/mo for our volume).
- **Security posture**: IAM least-privilege throughout, Secrets Manager for all credentials, CloudTrail + CloudWatch audit, no PII in logs.
- **Ready for provisioning** after Wave confirms §2 (access method + Microsoft 365 tenant questions). Trustify deploys in parallel once AWS resources are live.

---

## 1. How this handover works

**Wave = landlord. Trustify = operator.**

- Wave provisions AWS infrastructure (VPC, ALB, EC2, RDS, S3, SQS, IAM) — full spec in this document.
- Wave grants Trustify operational access credentials (one IAM user or cross-account role).
- Trustify installs, configures, deploys, and runs the app stack on top.
- When we ship new features or fix bugs, we push directly — **no per-change tickets to Wave**.

Why this model: it eliminates round-trip coordination delay. Wave keeps data sovereignty (everything lives in your AWS account, you own the audit trail, you can revoke access any time). Trustify keeps operational velocity.

---

## 2. What Wave provides

### AWS access

One IAM user (or cross-account role) for the Trustify team with these permissions on the eMoney resources:

- `rds:DescribeDBInstances` + Postgres connect (via IAM auth or master creds in Secrets Manager)
- `s3:GetObject` / `s3:PutObject` / `s3:ListBucket` on the eMoney attachments bucket + dashboard bucket
- `secretsmanager:GetSecretValue` on the eMoney secret(s)
- `bedrock:InvokeModel` on the Claude model ARN (see §7)
- `sqs:SendMessage` / `sqs:ReceiveMessage` / `sqs:DeleteMessage` on the eMoney SQS queues
- `lambda:InvokeFunction` on the webhook Lambda (n8n direct-invoke fallback path)
- `ssm:StartSession` on the n8n EC2 instance (SSH via Session Manager, no port 22)
- `cloudwatch:GetLogs` / `logs:FilterLogEvents` on the relevant log groups (for our own debugging)

### Endpoint + credential handoff

- **n8n instance URL**: `https://n8n.<your-domain>` + initial admin credentials
- **RDS endpoint**: hostname + port + initial DB user/password (we'll rotate after first login)
- **S3 bucket names**: dashboard bucket + attachments bucket
- **SQS queue URLs**: webhook queue + DLQ
- **Secrets Manager secret names** (ARNs preferred): RDS creds, webhook secret, Bedrock config, n8n encryption key

### Microsoft 365 info (3 questions — see §9)

### Ops

- **GitHub handles** for anyone on Wave's side who wants read access to the repo (we'll add them to [yoma-org/wave-emi-dashboard](https://github.com/yoma-org/wave-emi-dashboard))

---

## 3. What Trustify operates (on top of your AWS)

| Component | Source | How it's deployed |
|---|---|---|
| **Dashboard** (static HTML + assets) | [index.html](index.html) in the repo | GitHub Actions → S3 static bucket (ALB serves it per §4) |
| **Webhook Lambda** ([api/webhook.js](api/webhook.js)) | [`api/`](api) in the repo | GitHub Actions → AWS Lambda. Triggered by SQS from n8n Worker. |
| **n8n workflows** (Spooler + Worker + CRUD endpoints) | [`pipelines/`](pipelines) in the repo | Imported + configured via n8n UI directly on the EC2 |
| **Schema + migrations** | [sql/complete/emi_dashboard_schema_aws.sql](sql/complete/emi_dashboard_schema_aws.sql) + future migration files | Manual via RDS access (never auto-deployed) |
| **LLM integration** | [pipelines/_worker_v13_3_gemini_extract.js](pipelines/_worker_v13_3_gemini_extract.js) — prompt templates | Bedrock via IAM Wave grants |
| **Outlook credential** | n8n credential UI | Configured after §9 answers land |

Wave never needs to touch the app stack. If something breaks, Trustify debugs using the logs + access Wave provides, fixes the code, pushes, redeploys. Wave gets observability (CloudWatch logs) but the operational work is Trustify's.

---

## 4. Stack 1 — Dashboard (ALB + VPC Endpoint + S3)

**What it does**: serves the static `index.html` dashboard to Finance and E-Money operators.

### Architecture

```
User (browser)
    │  HTTPS 443
    ▼
Application Load Balancer (ALB)
    │  internal routing rule: Host = dashboard domain
    ▼
VPC Endpoint (Gateway type — S3)
    │  private traffic, never leaves AWS backbone
    ▼
S3 Bucket (static website assets)
    └── index.html  (dashboard app, single-file ~5MB)
    └── (any future CSS/JS assets)
```

### AWS resources to provision

| Resource | Type | Notes |
|---|---|---|
| **ALB** | Application Load Balancer — **internal** (`scheme=internal`) | Shared with Stack 2 (n8n UI). Not internet-facing. Reachable only from Wave corporate network / VPN. |
| **ALB Listener** | HTTPS 443 | Requires an ACM certificate for your domain. |
| **ALB Target Group** | (points to VPC Endpoint) | Forward rule: host = `dashboard.<your-domain>` |
| **VPC Endpoint** | Gateway endpoint — `com.amazonaws.<region>.s3` | Allows EC2/Lambda inside VPC to reach S3 without traversing the internet. Also keeps dashboard traffic private. |
| **S3 Bucket** | Standard | Name: e.g., `wave-emoney-dashboard`. Block all public access. Serve via ALB/VPC Endpoint only. |
| **S3 Bucket Policy** | Allow `s3:GetObject` from VPC Endpoint principal only | Ensures no direct public access. |

### How Trustify deploys

1. GitHub Actions pushes `index.html` (and any assets) to the S3 bucket via `s3 sync`.
2. No CloudFront cache invalidation needed — ALB fetches directly from S3 on each request (or you can add CloudFront in front of the ALB later for global latency).

### IAM permissions Trustify needs

```json
{
  "Effect": "Allow",
  "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"],
  "Resource": [
    "arn:aws:s3:::wave-emoney-dashboard",
    "arn:aws:s3:::wave-emoney-dashboard/*"
  ]
}
```

### 4.1 ALB → S3 mechanism — provisioning detail (App Integration)

**Technical note for Wave's provisioning team**: ALB target-group types are limited to **Instance, IP, or Lambda** — ALB cannot directly target a VPC Endpoint or S3 bucket. When implementing Stack 1, Wave will need one of three compatible patterns:

| Option | Mechanism | Trade-off |
|---|---|---|
| **A. Lambda proxy (recommended)** | ALB → small Lambda → reads from S3 via VPC Endpoint, returns response | ~50 lines of Node.js; integrates with existing IAM model; single-request latency +~20ms |
| **B. S3 website mode + redirect** | ALB HTTPS listener returns redirect to S3 static-website endpoint | Simplest, but S3 website endpoint is HTTP-only (not HTTPS) — doesn't meet PCI compliance |
| **C. CloudFront distribution** | Add CloudFront between ALB and S3 (reverses the "no CloudFront" decision from Apr 22) | Most AWS-native for static sites; adds a service previously dropped for simplicity |

**Recommendation**: Option A (Lambda proxy). Trustify can provide the proxy Lambda code. Keeps the ALB-centric design Huy specified.

### 4.2 Attachments bucket (App Integration)

Stack 1's dashboard bucket serves the app UI. A **second S3 bucket** is needed for attachment binaries (PDF, XLSX, images extracted from emails by n8n). This is a separate concern from dashboard hosting.

**Attachments bucket requirements**:

| Resource | Type | Notes |
|---|---|---|
| **S3 Bucket (attachments)** | Standard | Name: e.g., `wave-emoney-attachments`. Block all public access. |
| **Server-side encryption** | SSE-S3 (minimum) or SSE-KMS (preferred) | Attachments contain PII: employee names, MSISDNs, bank account numbers, signatures |
| **Bucket policy** | Allow `s3:GetObject` + `s3:PutObject` from `wave-emoney-ec2-role` (n8n EC2 writes) and `wave-emoney-lambda-role` (Lambda reads) only | No public access |
| **CORS configuration** | Allow `GET` from dashboard ALB domain only; no wildcard | Required for browser to fetch via presigned URL |
| **Object key convention** | `tickets/<ticket_number>/attachments/<filename>` | Keeps paths predictable + easy to enumerate per ticket |

**Preview flow** (browser loads PDF/image in dashboard):

1. User clicks "view attachment" in dashboard
2. Browser calls an **n8n HTTP-trigger workflow** (`GET /webhook/attachment-url?key=<s3-object-key>`) — see §5.2 below
3. n8n workflow uses AWS SDK (via EC2 instance role) to generate an S3 presigned URL with **1-hour TTL**
4. n8n returns the presigned URL to browser
5. Browser uses presigned URL directly with `PDF.js` or `<img src>` — bandwidth bypasses n8n
6. URL expires after TTL; re-fetch if needed

**Why this pattern**:
- Browser never holds long-lived AWS credentials
- Attachments bucket stays private (no public-access policy)
- Backend (n8n) gates access via IAM + app-level auth
- Short TTL limits blast radius of URL leakage

---

## 5. Stack 2 — n8n Worker (EC2 + Docker + EFS + RDS)

**What it does**: runs the n8n automation platform (self-hosted). n8n polls Outlook for new salary-disbursement emails, runs AI extraction, dispatches tickets. **Also provides a browser UI for operators** and serves **dashboard CRUD via HTTP-trigger workflows** (see §5.2).

### Architecture

```
User (browser — Trustify operator inspecting n8n UI + Wave operators for dashboard CRUD)
    │  HTTPS 443
    ▼
Application Load Balancer (ALB)
    │  listener rule: host = n8n.<your-domain>
    ▼
EC2 Instance — "n8n worker"
    │  (inside Auto Scaling group, min=1 max=1 for now)
    │  runs Docker / docker-compose
    │  n8n container listens on port 5678
    │  EFS mount at /home/ec2-user/n8n-data (config persistence)
    │
    ├──→ Amazon EFS (Elastic File System)
    │        stores n8n config, credentials, workflow definitions
    │        survives EC2 instance replacement
    │
    └──→ Amazon RDS — PostgreSQL (single instance)
             n8n uses this as its internal database
             (workflow execution history, credential store, queue state)
             ALSO hosts the emi database (ticket data) — see §5.1 below
```

### Why EFS

n8n stores its configuration (credentials, workflow state, encryption keys) on disk. If EC2 is replaced (e.g., stopped + restarted with a new instance), data on the instance volume is lost. EFS is a network filesystem that multiple EC2 instances can mount — in practice, it means n8n config survives any instance lifecycle event.

### EC2 setup (what Trustify installs)

The EC2 instance runs n8n via `docker-compose`. The compose file lives in the repo at `infra/docker-compose.n8n.yml` (Trustify will provide).

```yaml
# simplified structure — Trustify provides the full file
version: "3.8"
services:
  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=${RDS_HOST}
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=${RDS_USER}
      - DB_POSTGRESDB_PASSWORD=${RDS_PASSWORD}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - WEBHOOK_URL=https://n8n.<your-domain>/
    volumes:
      - /mnt/efs/n8n-data:/home/node/.n8n   # EFS mount
    restart: unless-stopped
```

Secrets (`RDS_PASSWORD`, `N8N_ENCRYPTION_KEY`) are fetched from **Secrets Manager** at startup via a startup script — they are never hardcoded.

### AWS resources to provision

| Resource | Type | Notes |
|---|---|---|
| **EC2 instance** | `t3.medium` recommended (n8n is memory-hungry) | Amazon Linux 2023 or Ubuntu 22.04. Install Docker + Docker Compose at launch. |
| **Auto Scaling group** | Min=1, Max=1 (single instance) | Ensures EC2 auto-recovers if it fails. Not for horizontal scaling — n8n is stateful. |
| **EFS File System** | Standard | One file system. Mount target in the same AZ as EC2. |
| **EFS Mount Target** | In the EC2 subnet | Security group: allow NFS (2049) from EC2 security group. |
| **ALB Target Group** | HTTP on port 5678 | Health check: `GET /healthz` → 200. |
| **ALB Listener Rule** | host = `n8n.<your-domain>` | Routes to EC2 Target Group. |
| **RDS PostgreSQL** | Single instance (`db.t3.micro` or `db.t3.small`) | PostgreSQL 15+. Database name: `n8n` + `emi`. Enable automated backups (7-day retention). |
| **Security groups** | EC2 → RDS (5432), ALB → EC2 (5678), EC2 → EFS (2049) | No port 22 open — use SSM Session Manager instead. |

### 5.1 RDS — single instance, two databases

Both Stack 2 (n8n internal DB) and Stack 3 (ticket data) need PostgreSQL. Options:

| Option | Setup | Trade-off |
|---|---|---|
| **Single RDS instance, two databases** | One `db.t3.small`. Database `n8n` for Stack 2. Database `emi` for Stack 3. | Simpler, cheaper. Both stacks go down together if RDS fails. |
| **Two RDS instances** | One `db.t3.micro` for n8n. One `db.t3.small` for emi (more data). | Isolated failure domains. Higher cost (+$15–30/mo). |

**Recommendation for initial deployment**: single instance with two databases. Migrate to two instances if Wave wants stronger isolation post-stabilization.

Use **IAM database authentication** or store the master password in Secrets Manager. Trustify will create dedicated database users with minimal privileges:

```sql
CREATE DATABASE n8n;
CREATE DATABASE emi;
CREATE USER n8n_app WITH PASSWORD '<from-secrets-manager>';
CREATE USER lambda_app WITH PASSWORD '<from-secrets-manager>';
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_app;
GRANT CONNECT, USAGE ON DATABASE emi TO n8n_app;  -- n8n reads emi for CRUD workflows
GRANT CONNECT, USAGE ON DATABASE emi TO lambda_app;
-- table-level grants applied after schema migration
```

### 5.2 Dashboard CRUD via HTTP-trigger workflows (App Integration) — **Option D**

**The architectural decision**: the Wave eMoney dashboard is a 9-page × 3-role × 7-step operations app. It needs to **read and write ticket data in RDS** continuously during operator workflows (list tickets, get ticket detail, update status, approve/reject, generate CSVs, etc.).

RDS exposes only TCP (port 5432), not HTTPS — browsers cannot talk to it directly. The chosen pattern is:

**Browser → ALB → n8n EC2 (port 5678) → HTTP-trigger workflow → RDS**

n8n's built-in Webhook trigger node exposes an HTTPS endpoint per workflow. Trustify builds one workflow per CRUD operation; each workflow queries RDS (using n8n's Postgres integration with the `n8n_app` user) and returns JSON.

**Why this pattern** (chosen over Lambda CRUD endpoints or RDS Data API):
- n8n EC2 is already in the stack with RDS access — no new AWS components
- Zero provisioning work from Wave beyond what's already specified in Stack 2
- Matches Huy's "add as n8n workflow with HTTP trigger" suggestion
- ~2-4 hours to build each endpoint; total CRUD surface: ~1-2 days of app work
- All CRUD traffic stays inside the VPC (PCI-friendly)

**n8n workflows to build** (non-exhaustive; exact list finalized during implementation):

| Endpoint | Purpose | Example path |
|---|---|---|
| List tickets | Dashboard home + role-specific views | `GET /webhook/tickets?role=finance&status=pending` |
| Get ticket detail | Single-ticket view with all fields | `GET /webhook/tickets/:id` |
| Update ticket status | State transitions (approve, reject, advance step) | `PATCH /webhook/tickets/:id/status` |
| Approve/reject | Role-specific action endpoints | `POST /webhook/tickets/:id/approve` |
| Generate presigned URL | Attachment preview (see §4.2) | `GET /webhook/attachment-url?key=...` |
| Activity log entries | Audit trail writes | `POST /webhook/activity` |

**Future migration path**: if dashboard traffic grows beyond a few hundred requests/day or tighter typing is desired, the CRUD layer can be migrated to Lambda functions. Current approach is optimized for delivery speed + minimal infra footprint.

### SSH access (no port 22)

Use **SSM Session Manager** for shell access. No bastion host, no port 22 open. EC2 instance profile must have `AmazonSSMManagedInstanceCore` policy attached.

```bash
# Trustify connects with:
aws ssm start-session --target <instance-id>
```

### IAM permissions Trustify needs (for EC2 instance profile)

```json
{
  "Effect": "Allow",
  "Action": [
    "secretsmanager:GetSecretValue"
  ],
  "Resource": "arn:aws:secretsmanager:<region>:<account>:secret:wave-emoney/*"
},
{
  "Effect": "Allow",
  "Action": [
    "bedrock:InvokeModel",
    "bedrock:InvokeModelWithResponseStream"
  ],
  "Resource": "arn:aws:bedrock:<region>::foundation-model/anthropic.claude-opus-4-7*"
},
{
  "Effect": "Allow",
  "Action": [
    "sqs:SendMessage",
    "sqs:GetQueueUrl"
  ],
  "Resource": "arn:aws:sqs:<region>:<account>:wave-emoney-webhook"
},
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject"
  ],
  "Resource": "arn:aws:s3:::wave-emoney-attachments/*"
},
{
  "Effect": "Allow",
  "Action": [
    "lambda:InvokeFunction"
  ],
  "Resource": "arn:aws:lambda:<region>:<account>:function:wave-emoney-webhook",
  "Comment": "Optional — direct-invoke fallback path if n8n needs synchronous Lambda response instead of SQS"
}
```

---

## 6. Stack 3 — Events (n8n → SQS → Lambda webhook)

**What it does**: decouples n8n's extraction pipeline from the Lambda that persists tickets to RDS. n8n sends a message to SQS after processing an email; SQS triggers the Lambda; Lambda writes the ticket record.

### Architecture

```
EC2 n8n Worker
    │  AWS SDK SQS SendMessage (IAM-signed, over VPC Endpoint)
    ▼
Amazon SQS — "wave-emoney-webhook" queue
    │  (standard queue, visibility timeout = 300s)
    │  Lambda trigger (batch size = 1)
    ▼
Lambda — webhook handler  (api/webhook.js)
    │  parses ticket JSON from SQS message body
    │  idempotent via message_id deduplication
    ▼
Amazon RDS — PostgreSQL (same instance as Stack 2, or separate)
    writes: tickets_v2, ticket_emails, ticket_attachments,
            ticket_vision_results, email_queue (status update),
            activity_log
```

### Why SQS (not direct Lambda invoke by default)

| Concern | Direct invoke | SQS-buffered |
|---|---|---|
| Lambda cold-start blocks n8n | Yes — n8n waits | No — n8n returns immediately after SendMessage |
| Lambda error loses ticket | Yes | No — message stays in queue, retried 3× |
| n8n timeout risk (15-min Outlook processing) | High if chained | Low — queues are independent |
| Dead-letter visibility | None | DLQ catches failed messages after 3 retries |

**Direct-invoke fallback is available** (EC2 instance role has `lambda:InvokeFunction` for the webhook Lambda) — used only if n8n needs a synchronous response from Lambda during a specific workflow step. Default path is SQS-buffered.

### AWS resources to provision

| Resource | Type | Notes |
|---|---|---|
| **SQS Queue** | Standard queue | Name: `wave-emoney-webhook`. Visibility timeout: 300s. Message retention: 4 days. |
| **SQS Dead-Letter Queue** | Standard queue | Name: `wave-emoney-webhook-dlq`. maxReceiveCount: 3. |
| **SQS Redrive policy** | Point main queue at DLQ | After 3 failed Lambda invocations, message lands in DLQ for manual inspection. |
| **Lambda function** | `webhook` | Runtime: Node.js 20.x. Handler: `api/webhook.handler`. Memory: 512 MB. Timeout: 60s. |
| **Lambda event source mapping** | SQS → Lambda | Batch size: 1. Bisect on error: true. |
| **Lambda execution role** | IAM role | See permissions below. |
| **Lambda VPC configuration** | **Required** — Lambda MUST be in the VPC to reach RDS in private subnet | 2 subnets across AZs; security group allows outbound 5432 to RDS SG |
| **VPC Endpoint — SQS** | Interface endpoint — `com.amazonaws.<region>.sqs` | Allows EC2 to reach SQS without NAT Gateway. |

### Lambda IAM execution role

```json
{
  "Effect": "Allow",
  "Action": [
    "sqs:ReceiveMessage",
    "sqs:DeleteMessage",
    "sqs:GetQueueAttributes"
  ],
  "Resource": "arn:aws:sqs:<region>:<account>:wave-emoney-webhook"
},
{
  "Effect": "Allow",
  "Action": ["secretsmanager:GetSecretValue"],
  "Resource": "arn:aws:secretsmanager:<region>:<account>:secret:wave-emoney/*"
},
{
  "Effect": "Allow",
  "Action": ["rds-db:connect"],
  "Resource": "arn:aws:rds-db:<region>:<account>:dbuser:<rds-resource-id>/lambda_app"
},
{
  "Effect": "Allow",
  "Action": ["s3:GetObject"],
  "Resource": "arn:aws:s3:::wave-emoney-attachments/*",
  "Comment": "Read attachments referenced in SQS messages by S3 key"
},
{
  "Effect": "Allow",
  "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
  "Resource": "arn:aws:logs:*:*:*"
}
```

### SQS message format (what n8n sends)

```json
{
  "ticket": {
    "company": "Kyaw Trading Co.",
    "type": "SalaryToMA",
    "currency": "MMK",
    "amount_requested": 245600,
    "from_email": "sender@example.com",
    "original_subject": "Salary disbursement April",
    "extracted_employees": [...],
    "email_approvals": [...]
  },
  "attachments": [
    {
      "s3_key": "tickets/TKT-042/attachments/bank_slip.pdf",
      "mime_type": "application/pdf",
      "filename": "bank_slip.pdf",
      "extracted_fields": { ... }
    }
  ],
  "source_email_id": "N8N-1712345678",
  "message_id": "<rfc-822-message-id-for-idempotency>"
}
```

**Authenticity model**: SQS queue is IAM-gated (only `wave-emoney-ec2-role` can send, only `wave-emoney-lambda-role` can consume). Authenticity is derived from IAM — no need for in-message HMAC. Lambda can optionally fetch `WEBHOOK_SECRET` from Secrets Manager for defense-in-depth if direct-invoke path is used instead of SQS.

### Large attachment handling

SQS message size limit is **256 KB**. Large attachments (PDFs >150KB after base64 inflation) must be uploaded by n8n to the **attachments S3 bucket first** (see §4.2), with only the `s3_key` referenced in the SQS message. Lambda reads the attachment from S3 if it needs the binary — most of the time, Lambda only persists metadata from the SQS message body and doesn't need the binary at all.

---

## 7. Supporting services

### IAM

Every stack has its own IAM role with least-privilege permissions:

| Role name (suggested) | Attached to | Key permissions |
|---|---|---|
| `wave-emoney-ec2-role` | EC2 instance profile (Stack 2) | Bedrock invoke, SQS SendMessage, Secrets Manager read, SSM Session Manager, S3 read/write on attachments bucket, Lambda invoke (optional direct-invoke path) |
| `wave-emoney-lambda-role` | Lambda execution role (Stack 3) | SQS consume, RDS connect (`lambda_app` user), Secrets Manager read, S3 read on attachments bucket, CloudWatch logs |
| `wave-emoney-cicd-role` | GitHub Actions OIDC | S3 sync (dashboard bucket), Lambda update-function-code |
| `wave-emoney-trustify-ops` | Trustify operator access | SSM Session Manager on EC2, CloudWatch logs read, RDS describe |

### Secrets Manager

Store all runtime secrets here. Suggested secret names:

| Secret name | Contents | Read by |
|---|---|---|
| `wave-emoney/rds-credentials` | `{ "host": "...", "port": 5432, "username": "...", "password": "..." }` | EC2 startup script, Lambda |
| `wave-emoney/n8n-config` | `{ "encryption_key": "...", "webhook_url": "..." }` | EC2 startup script |
| `wave-emoney/webhook-secret` | `{ "hmac_secret": "..." }` | n8n (signs, optional), Lambda (verifies, defense-in-depth) |
| `wave-emoney/bedrock-config` | `{ "model_id": "anthropic.claude-opus-4-7", "region": "..." }` | EC2 n8n Worker |
| `wave-emoney/outlook-credentials` | OAuth tokens for monitored mailbox | n8n credential store (managed via n8n UI — not stored in Secrets Manager directly) |

### AWS Bedrock

n8n calls Bedrock from EC2 (Stack 2) to extract structured data from email attachments.

- **Model**: `anthropic.claude-opus-4-7` (Claude Opus 4.7)
- **Region**: must match EC2 region (Bedrock is regional)
- **Access**: Wave must request Bedrock model access for the Claude Opus 4.7 model in the AWS console (Bedrock → Model access → Enable). This is a one-time manual step.
- **VPC Endpoint** (optional but recommended): `com.amazonaws.<region>.bedrock-runtime` — keeps Bedrock traffic inside the VPC.

---

## 8. Network summary (security groups)

### Access model — internal only

**ALB type: internal** (not internet-facing). The dashboard and n8n UI are operator tools — only Wave internal staff and Trustify engineers need access. No public exposure.

Users reach the ALB via one of these options (Wave decides):

| Option | How | When to use |
|---|---|---|
| **Corporate network / office CIDR** | ALB SG allows 443 from Wave office IP range(s) | All operators work from office |
| **AWS Client VPN** | VPN endpoint in the VPC; users connect VPN first | Mix of office + remote operators |
| **Site-to-site VPN** | Wave on-prem network peered to VPC | Wave already has on-prem infra |

**Wave must specify their access method before ALB is provisioned** — this determines subnets and security group rules.

### Security group rules

```
Wave corporate network / VPN
    │ 443 (HTTPS) — restricted to Wave IP range or VPN CIDR only
    ▼
[ALB] — internal, scheme=internal
    Security group:
      inbound:  443 from <Wave-CIDR or VPN-client-CIDR>  ← NOT 0.0.0.0/0
      outbound: 5678 to EC2 security group (n8n UI + HTTP-trigger workflows)
                (S3 traffic goes via VPC Endpoint or Lambda proxy, not through ALB targets)
    │
    ├─ rule: host = dashboard.<domain> → S3 (via Lambda proxy or CloudFront — see §4.1)
    └─ rule: host = n8n.<domain>       → EC2 port 5678

[EC2 n8n] — private subnet, no public IP
    Security group:
      inbound:  5678 from ALB security group only
      outbound: 5432 to RDS security group
                2049 to EFS security group
                443  to SQS VPC Endpoint
                443  to Bedrock VPC Endpoint
                443  to Secrets Manager VPC Endpoint
                443  to S3 VPC Endpoint

[RDS] — private subnet, no public IP
    Security group:
      inbound:  5432 from EC2 security group
                5432 from Lambda security group

[EFS] — private subnet
    Security group:
      inbound:  2049 (NFS) from EC2 security group only

[Lambda] — IN VPC (required to reach RDS in private subnet)
    Security group:
      outbound: 5432 to RDS security group
                443  to Secrets Manager VPC Endpoint
                443  to S3 VPC Endpoint (for attachment reads)
```

No port 22 anywhere. No public IP on EC2, RDS, or EFS. ALB is internal — not reachable from the public internet.

---

## 9. Microsoft 365 / Outlook — three questions (App Integration)

Separate track from the AWS side (different admin on your team, likely). Three answers unblock the Outlook credential work:

1. **Which mailbox does production monitor?**
   - Current (demo): `emoney@zeyalabs.ai` — if you want to keep this through transition, fine
   - Production: almost certainly a Wave-domain mailbox (e.g., `emoney@wave-mm.com` or similar)
   - Either works; just tell us which path
2. **Which Microsoft 365 tenant hosts that mailbox?**
3. **Who's your tenant admin?** Specifically: the person authorized to register Azure AD apps and grant admin consent.

Once answered: Trustify will run the **credential-overwrites pattern** (Appendix A) — one Azure app registered once by your admin, then all n8n Outlook credentials flow through it with click-through OAuth. No per-developer friction.

---

## 10. CI/CD — how Trustify deploys (on Wave's AWS)

Trustify handles this using **GitHub Actions + AWS OIDC**. Wave grants an OIDC role once; Trustify configures the Actions workflow. No long-lived access keys leave Wave's account.

| Target | Trigger | Safety |
|---|---|---|
| Dashboard static (S3 via ALB/CloudFront per §4.1) | Every commit to `main` → auto-deploy | Low risk — pure frontend, instantly revertable |
| Lambda webhook | Every commit to `main` → auto-deploy | Low risk — stateless, versioned, SQS-triggered |
| n8n workflows | **Manual** — imported via n8n UI when ready | n8n Community has no native git-sync; direct control preferred |
| Schema migrations | **Manual with review** — never auto | Auto-running DDL against prod is a recipe for outage |

Wave configures nothing beyond the OIDC role. Trustify sends the exact trust-policy JSON in the first sync.

---

## 11. Environment variables + credentials (App Integration)

Split between Lambda and n8n. Shared secrets (DB connection + webhook HMAC) live once in Secrets Manager; both sides fetch the same entry.

### Lambda webhook (Lambda function config + Secrets Manager)

| Var | Purpose | Source |
|---|---|---|
| `DB_HOST` + `DB_PORT` + `DB_NAME` | Postgres connection | Env var |
| `DB_USER` + `DB_PASSWORD` (or IAM auth token) | DB auth | Secrets Manager |
| `WEBHOOK_SECRET` | HMAC verifier for direct-invoke path (defense-in-depth) | Secrets Manager |
| `S3_ATTACHMENTS_BUCKET` | Attachments bucket name | Env var |
| `S3_REGION` + `AWS_REGION` | Region config | Env var |

### n8n (EC2 env + n8n credential UI)

| Config | Purpose | Source |
|---|---|---|
| `DB_HOST` + `DB_PORT` + `DB_NAME` + `DB_USER` + `DB_PASSWORD` | n8n reads/writes email_queue + ticket data | EC2 env vars (from Secrets Manager) |
| `WEBHOOK_SECRET` | HMAC signer for direct-invoke path | EC2 env var |
| `WEBHOOK_QUEUE_URL` | SQS queue target for webhook messages | EC2 env var |
| `BEDROCK_REGION` + `BEDROCK_MODEL_ID` | LLM extraction target (`anthropic.claude-opus-4-7`) | EC2 env var |
| `CREDENTIALS_OVERWRITE_DATA` | Microsoft OAuth app override (see Appendix A) | EC2 env var |
| `S3_ATTACHMENTS_BUCKET` | Attachments bucket for uploads + presigned URL generation | EC2 env var |
| Microsoft Outlook credential | Mailbox polling + Send Email | n8n credential UI |
| AWS Bedrock credential | Invoke model | n8n credential UI (cleanest: instance IAM role on EC2 — no static creds) |

### Shared secrets

`WEBHOOK_SECRET` is shared between Lambda and n8n — both read the same Secrets Manager entry. RDS credentials are also shared but we recommend separate DB users per component (`n8n_app` vs `lambda_app`) for audit clarity.

### Why Bedrock lives on n8n, not Lambda

Lambda webhook only persists pre-extracted tickets; it doesn't call the LLM. All extraction happens inside the n8n Worker pipeline (email + attachments → Bedrock → structured ticket), so Bedrock config lives with n8n, not Lambda.

---

## 12. Security posture — explicit requirements (App Integration)

Wave's security team will review this. These are the non-negotiables Trustify asks Wave's infra team to honor when provisioning, and that Trustify commits to follow on the app side.

### 12.1 IAM — least privilege only

- **No wildcard resources**. Every IAM policy scopes to specific ARNs (Lambda functions, SQS queues, Secrets Manager entries, S3 buckets, Bedrock model ARNs).
- **No `*` actions** on services handling PII (`secretsmanager`, `rds`, `s3` for attachments). Specify exact actions (`GetSecretValue`, `rds-db:connect`, `GetObject`).
- Each component (Lambda, EC2 n8n, operator user) gets its own role. No role sharing.
- Trustify's operator IAM user has read-only scope on observability (`cloudwatch`, `logs`), limited write on code-deploy targets (Lambda, S3 dashboard bucket). No direct prod DB write access; writes go through Lambda + n8n pipelines.

### 12.2 Network posture

- **RDS**: VPC-internal only, no public subnet, security group allows ingress only from Lambda + n8n EC2 security groups.
- **SQS**: no public access, IAM-gated only.
- **Lambda webhook**: no function URL, not exposed via API Gateway, not internet-reachable. Only SQS triggers or n8n direct invoke reach it.
- **n8n EC2**: no SSH on port 22 — all access via SSM Session Manager.
- **Bedrock**: called via VPC Endpoint (PrivateLink), not public internet.
- **S3 (both buckets)**: private (no public-access grant); dashboard bucket accessible via ALB → Lambda proxy; attachments bucket accessible only via presigned URLs generated by n8n.
- **ALB**: internal-only recommended (VPN / Direct Connect). Public + WAF only if Wave explicitly approves.

### 12.3 Secrets management

- **All secrets in Secrets Manager**. No plaintext secrets in env vars (env vars carry pointer names only, e.g., `SECRETS_ARN_WEBHOOK`).
- **No secrets in CloudWatch logs**. Lambda + n8n log levels must mask `WEBHOOK_SECRET`, `DB_PASSWORD`, Bedrock API keys (if used).
- **Rotation**: Wave rotates DB credentials + webhook secret quarterly; app consumes via Secrets Manager so rotation is transparent.

### 12.4 Data handling + PII

- **Payroll employee data** (name, MSISDN, amount per person) is sensitive.
- Stored at rest in RDS (encrypted by default) + in attachments S3 (enable SSE-S3 or SSE-KMS).
- In transit: all paths TLS (ALB → internal targets, Lambda → RDS, n8n → Bedrock).
- CloudWatch logging: **do not log** full employee lists or raw attachment bodies. Log only metadata (count, confidence, error type).
- Email attachments retained in S3 for `<retention-period>` (TBD with Wave compliance team).

### 12.5 Audit

- All AWS API calls captured in CloudTrail (Wave-level config; expected on).
- App-level audit: ticket state transitions captured in RDS (existing `tickets_v2` schema includes timestamps + actor).
- Failed logins / unauthorized webhook calls logged in CloudWatch with alert thresholds TBD.

> **Note for Wave's DevSecOps reviewer**: these requirements are listed explicitly because Rita flagged (2026-04-23) that Yoma's infra team may not default to these patterns. If any conflict with Yoma conventions, raise with Trustify and we'll reconcile before go-live — not after.

---

## 13. Deferred scope (not in AWS v1)

**Lambda `extract-employee`** — browser-upload employee roster → Bedrock OCR. Currently served from Vercel (`api/extract-employees.js`) during the PoC phase but **deferred** from AWS v1 for three reasons:

1. The main n8n email pipeline already extracts employee rows from attachments (see `_worker_v13_3_gemini_extract.js` responseSchema — `employees[]` is in the schema). Main flow covers ~90% of use cases.
2. The Vercel endpoint is a pre-AWS workaround; porting it to AWS without redesign adds routing + payload-limit complexity (1 MB Lambda payload cap, presigned-S3 upload pattern needed, auth gap to close).
3. Wave team has not exercised this path in demos; feature is low-signal.

**Re-add plan when needed**: easiest path is an **n8n workflow with HTTP trigger** (browser POSTs to an n8n webhook endpoint, n8n calls Bedrock via the existing Worker credentials, returns JSON). Cost: ~1–2 hours to add. No AWS-native complexity needed unless we later want scale-to-zero.

**Return-to-Client n8n webhook** (current PoC: `index.html:3250` calls `https://tts-test.app.n8n.cloud/webhook/return-to-client` directly). In AWS v1, this becomes a call to n8n on the Wave-hosted EC2 (internal URL, same `n8n.<your-domain>/webhook/return-to-client` path).

---

## 14. Open questions for the first sync

### 14.1 Preferred AWS region
Singapore (`ap-southeast-1`) is closest to Myanmar; any constraint we don't know about?

### 14.2 n8n hosting
Confirmed EC2 + EFS + Auto Scaling group per this spec. ECS Fargate alternative if Wave prefers (no strong preference from Trustify).

### 14.3 Dashboard ALB → S3 mechanism
Three options detailed in §4.1 (Lambda proxy / S3 website redirect / CloudFront). Wave's infra team picks based on PCI posture + existing patterns. Trustify recommends Lambda proxy.

### 14.4 Main-branch ownership long-term
Does [yoma-org/wave-emi-dashboard](https://github.com/yoma-org/wave-emi-dashboard) stay as the source of truth, or will Wave fork when Trustify winds down involvement? Affects CI/CD permanence.

### 14.5 Access method (internal ALB reach)
Corporate CIDR / Client VPN / Site-to-site VPN — Wave's call (see §8).

### 14.6 Microsoft 365 answers
Mailbox + tenant + admin — see §9.

### 14.7 Transition timeline
How long does Trustify keep shipping features / fixing bugs? ~8–12 weeks of active development is the working assumption.

---

## 15. Cost estimate (ap-southeast-1, monthly)

| Resource | Size | Est. cost/mo |
|---|---|---|
| ALB | 1 ALB, low traffic | ~$18 |
| EC2 (n8n) | `t3.medium`, on-demand | ~$30 |
| EFS | <5 GB (n8n config) | ~$2 |
| RDS PostgreSQL | `db.t3.small`, single-AZ | ~$28 |
| SQS | <1M messages | ~$0 (free tier) |
| Lambda | <1M invocations | ~$0 (free tier) |
| Secrets Manager | 5 secrets | ~$2.50 |
| VPC Endpoints (interface) | 4 endpoints × $7.50 | ~$30 |
| S3 (dashboard + attachments) | <10 GB total | ~$2 |
| Bedrock (Claude Opus 4.7) | Usage-based | ~$20–100 depending on email volume |
| **Total (excluding Bedrock)** | | **~$112/mo** |

Cost reduction options:
- Use `t3.small` for EC2 if n8n workload is light (single Outlook mailbox, <100 emails/day) — saves ~$15/mo
- Swap on-demand EC2 to Reserved Instance (1-year) for ~40% savings after stabilization
- Drop one VPC interface endpoint (e.g., Bedrock) if traffic is low — saves $7.50/mo (Bedrock still works via NAT, just not private)

---

## 16. Handoff checklist — for Wave to provision

### VPC & Networking
- [ ] VPC with at least 2 private subnets (different AZs for RDS Multi-AZ if needed later)
- [ ] **No public subnet needed** — ALB is internal-only
- [ ] Confirm access method: corporate CIDR / Client VPN / Site-to-site VPN
- [ ] Route tables configured (private subnets route via VPC Endpoints, not IGW)

### VPC Endpoints (keeps traffic private, avoids NAT Gateway costs)
- [ ] S3 Gateway endpoint
- [ ] SQS Interface endpoint
- [ ] Secrets Manager Interface endpoint
- [ ] Bedrock Runtime Interface endpoint (optional but recommended)
- [ ] SSM Interface endpoints (3 needed: `ssm`, `ssmmessages`, `ec2messages`)

### Stack 1 — Dashboard
- [ ] S3 dashboard bucket created, public access blocked, bucket policy restricts to VPC Endpoint / Lambda proxy
- [ ] S3 attachments bucket created, public access blocked, SSE-S3 or SSE-KMS enabled, CORS configured
- [ ] ACM certificate issued for `dashboard.<your-domain>`
- [ ] ALB listener rule for dashboard (mechanism per §4.1 — Lambda proxy, CloudFront, or redirect)
- [ ] (If Lambda proxy) Small S3-proxy Lambda deployed + target group configured

### Stack 2 — n8n EC2
- [ ] EFS file system created, mount target in EC2 subnet
- [ ] RDS PostgreSQL single instance created, `n8n` and `emi` databases created
- [ ] EC2 instance launched (Amazon Linux 2023, `t3.medium`)
  - [ ] EC2 instance profile with `wave-emoney-ec2-role`
  - [ ] `AmazonSSMManagedInstanceCore` policy on instance profile
  - [ ] EFS mounted at `/mnt/efs/n8n-data` (via `/etc/fstab`)
  - [ ] Docker + Docker Compose installed
- [ ] Auto Scaling group wrapping EC2 (min=1, max=1, health check type=EC2)
- [ ] ALB target group: HTTP 5678, health check `GET /healthz`
- [ ] ALB listener rule: host = `n8n.<your-domain>` → EC2 target group (serves both UI + HTTP-trigger CRUD workflows)
- [ ] ACM certificate for `n8n.<your-domain>`

### Stack 3 — SQS + Lambda
- [ ] SQS standard queue `wave-emoney-webhook` (visibility 300s)
- [ ] SQS DLQ `wave-emoney-webhook-dlq` with redrive policy (maxReceiveCount=3)
- [ ] Lambda function `wave-emoney-webhook` created (Node.js 20.x, 512 MB, 60s timeout)
- [ ] Lambda configured in VPC (2 private subnets, security group for RDS + S3 + Secrets Manager access)
- [ ] Lambda event source mapping: SQS → Lambda (batch size 1)
- [ ] Lambda execution role `wave-emoney-lambda-role` with permissions per §6

### IAM & Secrets
- [ ] All roles created (see §7 IAM table)
- [ ] OIDC provider for GitHub Actions added to the AWS account
- [ ] GitHub Actions role `wave-emoney-cicd-role` with trust policy for the Trustify repo
- [ ] All secrets created in Secrets Manager (see §7 Secrets Manager table)
- [ ] Bedrock model access enabled for `anthropic.claude-opus-4-7`

### Handoff to Trustify
- [ ] Share RDS endpoint + master credentials → Trustify rotates after first login
- [ ] Share n8n URL (`https://n8n.<your-domain>`) + initial admin password
- [ ] Share S3 bucket names (dashboard + attachments)
- [ ] Share SQS queue URLs
- [ ] Share Secrets Manager secret ARNs (so Trustify can reference by ARN in code)
- [ ] Confirm GitHub repo (yoma-org/wave-emi-dashboard) added to OIDC trust policy
- [ ] Microsoft 365 answers (mailbox, tenant, admin contact)

---

## 17. Recent change log (for reviewers who saw earlier drafts)

The architecture iterated substantially in the 48 hours before this package. Relevant if Wave reviewers have seen earlier drafts:

- **2026-04-22 PM**: CloudFront removed from initial design (Huy). Replaced by ALB → VPC Endpoint → S3 (with the Lambda proxy caveat noted in §4.1). Simpler, VPC-only, PCI-friendly.
- **2026-04-23 AM**: API Gateway removed. n8n invokes Lambda via AWS SDK direct or SQS; browser traffic flows ALB → n8n EC2 or ALB → S3 (via proxy). One less AWS service to provision.
- **2026-04-23 AM**: SQS adopted as the email-processing notification layer. Replaces pg_net (not available on managed RDS Postgres without extensions) + pg_cron sweeper. Visibility timeout + DLQ provide retry semantics.
- **2026-04-23 AM**: Lambda `extract-employee` deferred from v1 — see §13.
- **2026-04-23 AM (Rita standup)**: Wave-hosted AWS posture confirmed; no Trustify-side AWS account for eMoney.
- **2026-04-23 PM**: Option D (n8n HTTP-trigger workflows for dashboard CRUD) chosen to close the browser→RDS access gap — see §5.2.
- **2026-04-23 PM**: Attachments bucket treated as first-class resource with presigned-URL preview flow — see §4.2.

---

## Appendix A — Outlook OAuth: three paths

Trustify researched the options. Option 3 is the recommendation.

| Option | Who registers the Azure app | End-user UX | Fits Wave? |
|---|---|---|---|
| 1. n8n Cloud (paid SaaS) | n8n (their tenant) | One-click "Connect my account" | ❌ Data residency, can't audit in your tenant |
| 2. Self-hosted, per-user | Each developer, each credential | Paste tenant + client + secret per credential | ❌ Doesn't scale |
| 3. **Self-hosted + credential overwrites** | Your Microsoft admin registers ONE app, once | One-click "Connect my account" (same UX as Cloud) | ✅ **Recommended** |

### Option 3 setup

1. **Your Microsoft admin** registers a single Azure AD multi-tenant app in your Entra tenant:
   - Redirect URI: `https://<your-n8n-host>/rest/oauth2-credential/callback` (exact match, no trailing slash)
   - Delegated scopes: `openid profile offline_access Mail.ReadWrite Mail.Send` (add `Mail.ReadWrite.Shared` + `Mail.Send.Shared` if the target mailbox is shared)
   - Grant admin consent once
2. **Your AWS admin** sets the `CREDENTIALS_OVERWRITE_DATA` env var on the n8n instance with the client ID + secret (spec: [n8n docs](https://docs.n8n.io/hosting/configuration/configuration-examples/microsoft-oauth-credential-overwrites/))
3. When Trustify creates the Outlook credential in n8n, Trustify sees only "Connect my account" — no tenant/client/secret fields. All OAuth flows run through your app, audit trail lives in your tenant.

`offline_access` is mandatory — without it the refresh token isn't issued and the credential breaks after ~1 hour.

---

## Appendix B — Production quirks worth knowing

Things learned operating the PoC that will eventually come up:

1. **SQL files for handoff must be ASCII-only.** Decorative Unicode in comments (box-drawings, em-dashes) breaks DBeaver on Windows even though strict Postgres accepts it. The schema file is ASCII as of commit `b080869`. Apply the rule to any SQL handed over afterward.
2. **n8n Code node has a hard 60-second execution budget** per invocation. `Promise.allSettled` is used for parallel LLM calls to stay under. Don't serialize multi-attachment processing.
3. **Pipeline executions routinely run 15–25 seconds.** Budget SQS visibility timeout ≥ 60s so in-flight messages don't redeliver mid-processing. Lambda timeout for webhook consumer ≥ 30s.
4. **Microsoft Graph may truncate attachment lists** on emails with 5+ files where total size exceeds ~3MB per attachment. The "too-many-attachments" rejection gate assumes this; monitor and tune if volumes differ.
5. **Bedrock regional availability** — Claude Opus / Sonnet model IDs vary by region. Singapore and Sydney currently support `anthropic.claude-opus-4-7-*`; confirm the exact model ARN with AWS during provisioning.

---

## Appendix C — Architecture diagram

See [`emoney.drawio.png`](emoney.drawio.png) at the repo root for the visual architecture.

---

## Next step

~30-minute sync with Wave:
- Live demo of the current system (10 min)
- Walk through §2 (what Wave provides) + §9 (Microsoft 365 answers) together (15 min)
- Align on timeline + deliverables (5 min)

**Contact**:
- DK Nguyen (app + pipeline operations) — [huy.nguyen@trustifytechnology.com via shared Teams channel]
- Huy Nguyen Duc (AWS infrastructure) — [huy.nguyen@trustifytechnology.com via shared Teams channel]
- Vinh Nguyen Quang (project lead, Trustify side)

**Repo**: [https://github.com/yoma-org/wave-emi-dashboard](https://github.com/yoma-org/wave-emi-dashboard)

---

*This is v1 of the unified delivery package, dated 2026-04-23. The source documents [HANDOVER_INFRA.md](HANDOVER_INFRA.md) and [HANDOVER_APP.md](HANDOVER_APP.md) are canonical — regenerate this file as v2 if either source is updated.*
