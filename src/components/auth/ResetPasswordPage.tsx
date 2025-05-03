import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useNavigate } from 'react-router-dom';

export default function ResetPasswordPage() {
  const [newPassword, setNewPassword] = useState('');
  const [message, setMessage] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    // Forza Supabase a prendere il token di recovery dalla URL
    const checkRecovery = async () => {
      const hash = window.location.hash;
      if (hash.includes('type=recovery')) {
        await supabase.auth.getSession();
        setShowForm(true);
        setMessage('Inserisci la nuova password');
      } else {
        setMessage('Per reimpostare la password, usa il link che hai ricevuto via email.');
      }
      setLoading(false);
    };
    checkRecovery();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const { error } = await supabase.auth.updateUser({ password: newPassword });
    if (error) setMessage('Errore: ' + error.message);
    else setMessage('Password aggiornata con successo! Ora puoi effettuare il login.');
    setShowForm(false);
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="bg-white p-8 rounded-xl shadow-lg w-full max-w-md flex flex-col items-center">
        <div className="mb-4 flex flex-col items-center">
          <svg className="h-12 w-12 text-blue-500 mb-2" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 11c0-1.657-1.343-3-3-3s-3 1.343-3 3c0 1.306.835 2.417 2 2.83V17h2v-3.17c1.165-.413 2-1.524 2-2.83z" />
            <path strokeLinecap="round" strokeLinejoin="round" d="M17 11V7a5 5 0 00-10 0v4a5 5 0 0010 0z" />
          </svg>
          <h2 className="text-2xl font-bold mb-1 text-center">Reset Password</h2>
        </div>
        {loading ? (
          <p className="mb-4 text-center text-gray-700">Caricamento...</p>
        ) : (
          <>
            {message && <p className="mb-4 text-center text-gray-700">{message}</p>}
            {showForm && (
              <form onSubmit={handleSubmit} className="space-y-4 w-full">
                <input
                  type="password"
                  placeholder="Nuova password"
                  value={newPassword}
                  onChange={e => setNewPassword(e.target.value)}
                  className="w-full px-3 py-2 border rounded"
                  required
                />
                <button
                  type="submit"
                  className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700"
                >
                  Aggiorna password
                </button>
              </form>
            )}
            {!showForm && (
              <button
                onClick={() => navigate('/login')}
                className="mt-4 w-full bg-gray-200 text-gray-700 py-2 rounded hover:bg-gray-300"
              >
                Torna al login
              </button>
            )}
          </>
        )}
      </div>
    </div>
  );
} 