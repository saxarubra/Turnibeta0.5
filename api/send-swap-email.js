const { Resend } = require('resend');
require('dotenv').config();

// Coda per gestire le richieste in modo sequenziale
let emailQueue = [];
let isProcessing = false;

// Funzione di utilità per il retry con backoff più aggressivo
async function retryWithBackoff(fn, maxRetries = 5, initialDelay = 2000) {
  let retries = 0;
  let delay = initialDelay;

  while (true) {
    try {
      return await fn();
    } catch (error) {
      if (error.name === 'rate_limit_exceeded' && retries < maxRetries) {
        console.log(`Rate limit exceeded, retrying in ${delay}ms... (attempt ${retries + 1}/${maxRetries})`);
        await new Promise(resolve => setTimeout(resolve, delay));
        delay *= 2; // Exponential backoff
        retries++;
        continue;
      }
      throw error;
    }
  }
}

// Funzione per processare la coda
async function processQueue() {
  if (isProcessing || emailQueue.length === 0) return;
  
  isProcessing = true;
  const { req, res, requestId } = emailQueue[0];
  
  try {
    const resend = new Resend(process.env.VITE_RESEND_API_KEY || process.env.RESEND_API_KEY);
    const { to, subject, html } = req.body;
    const fromAddress = process.env.VITE_EMAIL_FROM || 'onboarding@resend.dev';
    const recipient = to.includes('@example.com') ? process.env.GMAIL_USER || 'saxarubra915@gmail.com' : to;

    // Invia l'email con retry
    const { data, error } = await retryWithBackoff(async () => {
      const result = await resend.emails.send({
        from: fromAddress,
        to: recipient,
        subject: subject,
        html: html,
      });
      return result;
    });

    if (error) {
      console.error(`[${requestId}] Resend API error:`, error);
      res.status(500).json({ 
        error: error.message,
        details: error,
        requestId: requestId
      });
    } else {
      console.log(`[${requestId}] Email inviata con successo:`, {
        id: data.id,
        to: recipient,
        subject: subject
      });

      res.status(200).json({ 
        message: 'Email inviata!', 
        messageId: data.id,
        requestId: requestId,
        recipient: recipient
      });
    }
  } catch (error) {
    console.error(`[${requestId}] Error sending email:`, error);
    res.status(500).json({ 
      error: error.message,
      requestId: requestId,
      stack: error.stack
    });
  } finally {
    emailQueue.shift(); // Rimuovi la richiesta processata dalla coda
    isProcessing = false;
    if (emailQueue.length > 0) {
      // Processa la prossima richiesta nella coda
      setTimeout(processQueue, 1000); // Aspetta 1 secondo prima di processare la prossima
    }
  }
}

export default async function handler(req, res) {
  // Header CORS per tutte le richieste
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Allow-Credentials', 'true');

  // Gestione preflight (OPTIONS)
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  const requestId = Math.random().toString(36).substring(7);
  console.log(`[${requestId}] Ricevuta richiesta POST a /api/send-swap-email`);
  console.log(`[${requestId}] Body della richiesta:`, JSON.stringify(req.body, null, 2));

  // Verifica la presenza dell'API key
  const apiKey = process.env.VITE_RESEND_API_KEY || process.env.RESEND_API_KEY;
  if (!apiKey) {
    console.error(`[${requestId}] API key non configurata`);
    res.status(500).json({ error: 'Email service not configured' });
    return;
  }

  // Verifica il metodo HTTP
  if (req.method !== 'POST') {
    console.log(`[${requestId}] Metodo non consentito:`, req.method);
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  // Verifica i campi obbligatori
  const { to, subject, html } = req.body;
  if (!to || !subject || !html) {
    console.log(`[${requestId}] Campi mancanti:`, { 
      to: to ? 'presente' : 'mancante',
      subject: subject ? 'presente' : 'mancante',
      html: html ? 'presente' : 'mancante'
    });
    res.status(400).json({ error: 'Missing required fields' });
    return;
  }

  // Aggiungi la richiesta alla coda
  emailQueue.push({ req, res, requestId });
  
  // Se non ci sono altre richieste in elaborazione, inizia a processare
  if (!isProcessing) {
    processQueue();
  } else {
    console.log(`[${requestId}] Richiesta in coda. Posizione: ${emailQueue.length}`);
  }
} 