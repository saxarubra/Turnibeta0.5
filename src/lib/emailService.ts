import { SwapRequestEmail } from '../emails/SwapRequestEmail';
import { render } from '@react-email/render';
import { supabase } from './supabase';

export interface SwapRequestEmailData {
  swapId: string;
  fromEmployee: string;
  toEmployee: string;
  fromShift: string;
  toShift: string;
  date: string;
}

const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // 1 secondo

async function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function updateEmailSentStatus(swapId: string, sent: boolean) {
  const { error } = await supabase
    .from('shift_swaps')
    .update({ email_sent: sent })
    .eq('id', swapId);

  if (error) {
    console.error('Errore nell\'aggiornamento dello stato email:', error);
    throw error;
  }
}

export async function sendSwapRequestEmail(data: SwapRequestEmailData) {
  console.log('Chiamata sendSwapRequestEmail', data);
  let retries = 0;
  let lastError = null;

  while (retries < MAX_RETRIES) {
    try {
      console.log(`Tentativo ${retries + 1} di invio email con dati:`, data);
      
      const baseUrl = window.location.origin;
      console.log('Base URL:', baseUrl);

      const emailHtml = await render(
        SwapRequestEmail({
          swapId: data.swapId,
          requesterName: data.fromEmployee,
          requestedName: data.toEmployee,
          requesterShift: data.fromShift,
          requestedShift: data.toShift,
          baseUrl: baseUrl,
        })
      );
      console.log('Email template renderizzato');

      // Verifica se l'email è già stata inviata
      const { data: swapData, error: swapError } = await supabase
        .from('shift_swaps')
        .select('email_sent')
        .eq('id', data.swapId)
        .single();

      if (swapError) {
        throw swapError;
      }

      if (swapData?.email_sent) {
        console.log('Email già inviata per questo scambio');
        return { success: true, alreadySent: true };
      }

      // Determina il destinatario: se data.toEmployee è un'email, usala, altrimenti usa l'email dell'utente
      const destinatario = 'saxarubra915@gmail.com';

      console.log('Sto per chiamare la fetch verso il backend!');
      const response = await fetch('http://localhost:4000/api/send-swap-email', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          to: destinatario,
          subject: 'Richiesta di autorizzazione scambio turno',
          html: emailHtml,
        }),
      });
      console.log('Risposta fetch:', response);

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Errore nell'invio dell'email: ${errorText}`);
      }

      const result = await response.json();
      console.log('Email inviata con successo:', result);

      await updateEmailSentStatus(data.swapId, true);

      return { success: true, messageId: result.messageId };
    } catch (error) {
      console.error(`Errore nel tentativo ${retries + 1}:`, error);
      lastError = error;
      retries++;
      
      if (retries < MAX_RETRIES) {
        console.log(`Riprovo tra ${RETRY_DELAY}ms...`);
        await sleep(RETRY_DELAY);
      }
    }
  }

  throw lastError || new Error('Tentativi di invio email esauriti');
} 