import { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { ArrowLeft } from 'lucide-react';

interface PasswordResetFormProps {
  onBack: () => void;
}

export function PasswordResetForm({ onBack }: PasswordResetFormProps) {
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [errorMessage, setErrorMessage] = useState('');
  const { resetPassword } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus('loading');
    setErrorMessage('');
    
    try {
      await resetPassword(email);
      setStatus('success');
    } catch (err: any) {
      setStatus('error');
      setErrorMessage(err.message || 'Non è stato possibile inviare l\'email di recupero');
      console.error('Password reset error:', err);
    }
  };

  return (
    <div className="space-y-4">
      <button
        onClick={onBack}
        className="flex items-center text-sm text-gray-600 hover:text-gray-800"
      >
        <ArrowLeft className="h-4 w-4 mr-1" />
        Torna al login
      </button>

      <h2 className="text-2xl font-bold text-gray-900">Recupera password</h2>
      <p className="text-sm text-gray-600">
        Inserisci il tuo indirizzo email e ti invieremo un link per reimpostare la password.
      </p>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="email" className="block text-sm font-medium text-gray-700">
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            required
          />
        </div>

        {status === 'error' && (
          <p className="text-red-500 text-sm">
            {errorMessage}
          </p>
        )}

        {status === 'success' && (
          <p className="text-green-500 text-sm">
            Email inviata! Controlla la tua casella di posta (inclusa la cartella spam) per il link di recupero.
          </p>
        )}

        <button
          type="submit"
          disabled={status === 'loading' || status === 'success'}
          className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
        >
          {status === 'loading' ? 'Invio in corso...' : 'Invia email di recupero'}
        </button>
      </form>
    </div>
  );
}