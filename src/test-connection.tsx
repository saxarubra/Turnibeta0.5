import React, { useEffect, useState } from 'react';
import { supabase } from './lib/supabase';

export function TestConnection() {
  const [status, setStatus] = useState<string>('Verifica connessione in corso...');
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<any[] | null>(null);

  useEffect(() => {
    const testConnection = async () => {
      try {
        setStatus('Connessione a Supabase...');
        
        // Test 1: Verifica se le variabili d'ambiente sono caricate
        const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
        const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
        
        if (!supabaseUrl || !supabaseKey) {
          throw new Error('Variabili d\'ambiente mancanti: VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY');
        }
        
        setStatus('Variabili d\'ambiente caricate correttamente');
        
        // Test 2: Prova a recuperare i dati dalla tabella users
        setStatus('Recupero dati dalla tabella users...');
        const { data: usersData, error: usersError } = await supabase
          .from('users')
          .select('*')
          .limit(5);
          
        if (usersError) {
          throw usersError;
        }
        
        setData(usersData);
        setStatus('Connessione riuscita! Dati recuperati con successo.');
      } catch (err: any) {
        console.error('Errore di connessione:', err);
        setError(err.message || 'Errore sconosciuto');
        setStatus('Connessione fallita');
      }
    };
    
    testConnection();
  }, []);

  return (
    <div className="p-4 max-w-md mx-auto bg-white rounded-xl shadow-md overflow-hidden md:max-w-2xl m-4">
      <div className="p-8">
        <div className="uppercase tracking-wide text-sm text-indigo-500 font-semibold mb-2">
          Test Connessione Supabase
        </div>
        <div className="mt-2">
          <p className="text-gray-700">
            <span className="font-bold">Stato:</span> {status}
          </p>
          {error && (
            <div className="mt-2 p-2 bg-red-100 text-red-700 rounded">
              <p className="font-bold">Errore:</p>
              <p>{error}</p>
            </div>
          )}
          {data && (
            <div className="mt-4">
              <p className="font-bold">Dati recuperati:</p>
              <pre className="mt-2 p-2 bg-gray-100 rounded overflow-auto max-h-60">
                {JSON.stringify(data, null, 2)}
              </pre>
            </div>
          )}
        </div>
      </div>
    </div>
  );
} 