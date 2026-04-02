export default function handler(req, res) {
  // CORS headers for n8n Cloud
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

  const ticket = req.body;
  if (!ticket || !ticket.company) {
    return res.status(400).json({ error: 'Missing required field: company' });
  }

  // Generate redirect URL with base64-encoded ticket data
  const encoded = Buffer.from(JSON.stringify(ticket)).toString('base64');
  const url = `https://wave-emi-dashboard.vercel.app/?n8n_ticket=${encoded}`;

  return res.status(200).json({
    success: true,
    dashboard_url: url,
    company: ticket.company,
    amount: ticket.amount_requested || 0,
    message: `Ticket for ${ticket.company} ready. Open dashboard_url to auto-create.`,
  });
}
