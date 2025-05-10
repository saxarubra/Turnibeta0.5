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

export default function handler(req, res) {
  res.status(200).json({ ok: true, message: "API attiva!" });
} 