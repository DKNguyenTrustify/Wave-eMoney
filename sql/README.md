---
name: sql_readme
aliases: ["SQL Folder Guide"]
description: Navigation guide for the wave-emi-dashboard SQL folder. Two naming conventions coexist - numbered migrations (01-14) from Binh's original + enhancements, and feature-named scripts (kan46_*) for KAN-46 durable queue work.
type: reference
topics: [sql, database, schema, migrations, guide]
status: active
created: 2026-04-20
last_reviewed: 2026-04-20
---

# SQL Folder Guide

This folder contains all SQL for the Wave EMI Dashboard's Supabase database. Two naming conventions coexist by design:

## Chronological migrations (01-14)

Numbered in migration order from the original schema + subsequent enhancements. Run in sequence for a fresh environment.

| File | Purpose |
|---|---|
| `01_binh_original_schema.sql` | Binh's original table definitions |
| `02_enhanced_schema.sql` | DK's enhancements on top of Binh's schema |
| `03_bridge_view.sql` | Bridge view for legacy compatibility |
| `04_data_migration.sql` | One-time data migration script |
| `05_rollback.sql` | Rollback for migration 04 |
| `06_verification_queries.sql` | Post-migration verification |
| `07_security_storage_private.sql` | Private storage bucket setup |
| `08_security_rls_policies.sql` | Row-Level Security policies |
| `09_backfill_storage_paths.sql` | Backfill storage paths for existing rows |
| `10_storage_objects_rls.sql` | RLS on storage.objects |
| `11_fix_activity_log_fk.sql` | Fix foreign key on activity_log |
| `12_harden_activity_log.sql` | Harden activity log constraints |
| `13_kan36_extraction_fields.sql` | KAN-36 extraction fields added |
| `14_kan36_source_wallet_currency.sql` | KAN-36 source wallet currency |

## KAN-46 feature scripts (descriptive names)

Feature-oriented, not chronological. For the durable queue architecture (see `decisions/ADR-001_supabase_durable_queue.md` and `ADR-002_pg_cron_plus_trigger_scheduling.md`).

| File | Purpose |
|---|---|
| `kan46_schema_v1.sql` | `email_queue` table + indexes + `worker_config` + audit view |
| `kan46_v13_1_triggers.sql` | Database trigger + pg_cron conditional sweeper |
| `kan46_v13_1_rollback.sql` | Rollback script (disable trigger + unschedule cron) |
| `kan46_verify_v1.sql` | Post-deploy verification queries |
| `kan46_verify_spooler_test.sql` | Burst test verification queries |

## Maintenance scripts (reusable, project-general)

Reusable scripts for database lifecycle operations. Not tied to any specific KAN ticket.

| File | Purpose |
|---|---|
| `hard_reset_all_data.sql` | Clear ALL ticket/queue/log data for a fresh slate. Drops legacy `tickets` table. Preserves schemas, worker_config, triggers, pg_cron jobs, RLS policies. Use before client handover or at end-of-quarter. |

## Why the mixed naming?

- Numbered files are from the pre-KAN-46 era when Binh and DK iterated schema together. Chronological order matters; file 10 depends on file 09.
- KAN-46 files are self-contained features that don't cleanly fit into a linear migration history. Descriptive names make their purpose clearer at a glance.

## When to add new SQL

- **If it's a migration** (alters existing tables, adds new tables that other scripts depend on): use the next numbered prefix (`15_description.sql`)
- **If it's a feature-specific artifact** (KAN-NN script, verification query, rollback script): use descriptive name (`kanNN_feature.sql`)
- **If it's a one-off query** (debugging, reports, ad-hoc): don't add to this folder. Save to a separate scratchpad or memory file.

## Related

- `decisions/ADR-001_supabase_durable_queue.md` — queue architecture decision
- `decisions/ADR-002_pg_cron_plus_trigger_scheduling.md` — scheduling architecture decision
- `docs/kan46_v13_1_rollback_runbook.md` — operational rollback guide
- `memory/reference_supabase_pg_cron_pg_net.md` — Supabase extensions reference
