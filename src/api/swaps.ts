import { supabase } from '../lib/supabase';

export const getSwaps = async () => {
  const { data, error } = await supabase
    .from('shift_swaps')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
};

export const createSwap = async (swapData: {
  date: string;
  from_employee: string;
  to_employee: string;
  from_shift: string;
  to_shift: string;
  status: string;
}) => {
  const { data, error } = await supabase
    .from('shift_swaps')
    .insert(swapData)
    .select()
    .single();

  if (error) throw error;
  return data;
};

export const updateSwapStatus = async (swapId: string, status: string) => {
  const { data, error } = await supabase
    .from('shift_swaps')
    .update({ status })
    .eq('id', swapId)
    .select()
    .single();

  if (error) throw error;
  return data;
};

export async function handleSwapResponse(swapId: string, action: 'authorize' | 'reject') {
  try {
    console.log(`Gestione risposta per lo scambio ${swapId} con azione: ${action}`);
    
    // Recupera i dettagli dello scambio
    const { data: swap, error: swapError } = await supabase
      .from('shift_swaps')
      .select('*')
      .eq('id', swapId)
      .single();

    if (swapError) {
      console.error('Errore nel recupero dello scambio:', swapError);
      throw swapError;
    }
    
    if (!swap) {
      console.error('Scambio non trovato');
      throw new Error('Swap not found');
    }
    
    console.log('Scambio trovato:', swap);

    if (action === 'authorize') {
      // Aggiorna lo stato dello scambio a "authorized"
      console.log('Aggiornamento stato a "authorized"');
      const { error: updateError } = await supabase
        .from('shift_swaps')
        .update({ status: 'authorized' })
        .eq('id', swapId);

      if (updateError) {
        console.error('Errore nell\'aggiornamento dello stato:', updateError);
        throw updateError;
      }

      console.log('Scambio autorizzato con successo');
      return { success: true, message: 'Swap authorized successfully' };
    } else {
      // Rifiuta lo scambio
      console.log('Aggiornamento stato a "rejected"');
      const { error: updateError } = await supabase
        .from('shift_swaps')
        .update({ status: 'rejected' })
        .eq('id', swapId);

      if (updateError) {
        console.error('Errore nell\'aggiornamento dello stato:', updateError);
        throw updateError;
      }

      console.log('Scambio rifiutato con successo');
      return { success: true, message: 'Swap rejected successfully' };
    }
  } catch (error) {
    console.error('Error handling swap response:', error);
    return { success: false, error };
  }
} 