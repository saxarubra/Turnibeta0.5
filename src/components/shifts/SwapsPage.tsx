import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { format } from 'date-fns';
import { it } from 'date-fns/locale';
import { sendSwapRequestEmail } from '../../lib/emailService';

interface Swap {
  id: string;
  date: string;
  from_employee: string;
  to_employee: string;
  from_shift: string;
  to_shift: string;
  status: string;
  created_at: string;
}

interface SwapsPageProps {
  onClose: () => void;
}

export function SwapsPage({ onClose }: SwapsPageProps) {
  const [swaps, setSwaps] = useState<Swap[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { user } = useAuth();

  const loadSwaps = async () => {
    try {
      const { data, error } = await supabase
        .from('shift_swaps')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setSwaps(data || []);
    } catch (err) {
      console.error('Error loading swaps:', err);
      setError('Errore nel caricamento degli scambi');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSwaps();
  }, []);

  const handleSwapResponse = async (swapId: string, action: 'authorize' | 'reject') => {
    try {
      const swap = swaps.find(s => s.id === swapId);
      if (action === 'authorize') {
        if (!swap || swap.status !== 'authorized') {
          setError('Lo scambio deve essere prima autorizzato via email!');
          return;
        }
      }
      const { error } = await supabase
        .from('shift_swaps')
        .update({ status: action === 'authorize' ? 'accepted' : 'rejected' })
        .eq('id', swapId);

      if (error) throw error;
      await loadSwaps();
    } catch (err) {
      console.error('Error handling swap response:', err);
      setError('Errore nella gestione dello scambio');
    }
  };

  const handleAcceptSwap = async (swapId: string) => {
    try {
      const { error } = await supabase
        .from('shift_swaps')
        .update({ status: 'pending' })
        .eq('id', swapId);

      if (error) throw error;
      await loadSwaps();
    } catch (err) {
      console.error('Error accepting swap:', err);
      setError('Errore nell\'accettazione dello scambio');
    }
  };

  if (loading) return <div>Caricamento...</div>;
  if (error) return <div className="text-red-500">{error}</div>;

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-full max-w-2xl shadow-lg rounded-md bg-white">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold text-gray-800">Gestione Scambi Turno</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700"
          >
            <span className="sr-only">Chiudi</span>
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        
        <div className="space-y-4">
          {swaps.map((swap) => (
            <div
              key={swap.id}
              className="bg-gray-50 p-4 rounded-lg"
            >
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-sm text-gray-900">
                    <span className="font-medium">{swap.from_employee}</span>
                    {' ('}{swap.from_shift}{') '}
                    <span className="text-gray-500">ha scambiato con</span>
                    {' '}
                    <span className="font-medium">{swap.to_employee}</span>
                    {' ('}{swap.to_shift}{')'}
                  </p>
                  <p className="text-xs text-gray-500 mt-1">
                    <span className="font-medium">Data turno:</span> {format(new Date(swap.date), 'dd/MM/yyyy', { locale: it })} - 
                    <span className="font-medium ml-2">Richiesto il:</span> {format(new Date(swap.created_at), 'dd/MM/yyyy', { locale: it })} alle{' '}
                    {format(new Date(swap.created_at), 'HH:mm', { locale: it })}
                    {' - Stato: '}
                    <span className={`font-medium ${
                      swap.status === 'accepted' ? 'text-green-600' :
                      swap.status === 'rejected' ? 'text-red-600' :
                      swap.status === 'cancelled' ? 'text-gray-600' :
                      swap.status === 'authorized' ? 'text-blue-600' :
                      'text-yellow-600'
                    }`}>
                      {swap.status === 'accepted' ? 'Accettato' :
                       swap.status === 'rejected' ? 'Rifiutato' :
                       swap.status === 'cancelled' ? 'Annullato' :
                       swap.status === 'authorized' ? 'Autorizzato' :
                       'In attesa di autorizzazione'}
                    </span>
                  </p>
                </div>
                <div className="flex space-x-2">
                  {user?.email === swap.to_employee && swap.status === 'draft' && (
                    <button
                      onClick={() => handleAcceptSwap(swap.id)}
                      className="px-3 py-1 text-sm bg-green-500 text-white rounded hover:bg-green-600"
                    >
                      Accetta
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
          
          {swaps.length === 0 && (
            <p className="text-center text-gray-500 py-4">Nessun cambio turno registrato</p>
          )}
        </div>
      </div>
    </div>
  );
}