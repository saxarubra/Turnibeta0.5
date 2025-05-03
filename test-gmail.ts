import { sendGmailEmail } from './src/lib/gmailService';

sendGmailEmail({
  to: 'saxarubra915@gmail.com',
  subject: 'Test invio manuale',
  html: '<b>Funziona!</b>',
}).then(() => {
  console.log('Test completato!');
}).catch((err) => {
  console.error('Errore durante l\'invio:', err);
}); 