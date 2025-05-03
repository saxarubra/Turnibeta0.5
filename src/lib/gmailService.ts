// L'invio email ora avviene solo tramite la serverless function /api/send-swap-email.js
// Questo file è stato lasciato vuoto per evitare errori di import lato frontend.

import nodemailer from 'nodemailer';

export interface GmailEmailData {
  to: string;
  subject: string;
  html: string;
}

export async function sendGmailEmail(data: GmailEmailData) {
  console.log('Chiamata a sendGmailEmail con:', data);
  
  // Configura il trasportatore SMTP di Gmail
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.GMAIL_USER || 'saxarubra915@gmail.com',
      pass: process.env.GMAIL_APP_PASSWORD, // Password per le app di Gmail
    },
  });

  // Invia l'email
  const info = await transporter.sendMail({
    from: `Turni <${process.env.GMAIL_USER || 'saxarubra915@gmail.com'}>`,
    to: data.to,
    subject: data.subject,
    html: data.html,
  });

  console.log('Email inviata:', info.messageId);
  return info;
} 