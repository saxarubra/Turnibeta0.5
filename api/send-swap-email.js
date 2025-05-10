const { Resend } = require('resend');

module.exports = async (req, res) => {
  if (req.method === 'GET') {
    res.status(200).json({ ok: true, message: 'API attiva!' });
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method Not Allowed' });
    return;
  }

  try {
    const resend = new Resend(process.env.VITE_RESEND_API_KEY || process.env.RESEND_API_KEY);
    const { to, subject, html } = req.body || {};
    const fromAddress = process.env.VITE_EMAIL_FROM || 'onboarding@resend.dev';
    if (!to || !subject || !html) {
      res.status(400).json({ error: 'Missing required fields' });
      return;
    }
    // Invia l'email (mock, rimuovi il commento per invio reale)
    // const { data, error } = await resend.emails.send({ from: fromAddress, to, subject, html });
    // if (error) throw error;
    res.status(200).json({ message: 'Email inviata (mock)!', to, subject });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}; 