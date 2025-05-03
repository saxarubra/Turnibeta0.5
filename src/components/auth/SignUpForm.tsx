import { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';

const EMPLOYEE_CODES = [
  'ADMIN', 'BO', 'AA', 'CP', 'CT', 'CH', 'CF', 'DV', 'AD', 'DM', 'FO',
  'GM', 'IT', 'CA', 'LP', 'LG', 'MA', 'MO', 'MI', 'NF', 'PN',
  'PC', 'CB', 'RS', 'SC', 'SI', 'DG', 'SG', 'TJ', 'VE'
];

export function SignUpForm() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [employeeCode, setEmployeeCode] = useState('');
  const [error, setError] = useState('');
  const { signUp } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    
    if (!employeeCode) {
      setError('Seleziona il tuo codice dipendente');
      return;
    }

    try {
      // Check if employee code exists in users table
      const { data: existingUsers, error: usersError } = await supabase
        .from('users')
        .select('id')
        .eq('full_name', employeeCode)
        .maybeSingle();

      if (usersError) {
        console.error('Error checking existing users:', usersError);
        throw new Error('Errore durante la verifica del codice dipendente');
      }

      if (existingUsers) {
        setError('Questo codice dipendente è già registrato');
        return;
      }

      // If code is not in use, proceed with signup
      await signUp(email, password, employeeCode);
      
      // Crea l'utente nella tabella users
      const { error: insertError } = await supabase
        .from('users')
        .insert({
          id: (await supabase.auth.getUser()).data.user?.id,
          full_name: employeeCode,
          role: employeeCode === 'ADMIN' ? 'admin' : 'user'
        });
        
      if (insertError) {
        console.error('Error creating user record:', insertError);
        throw new Error('Errore durante la creazione del profilo utente');
      }
    } catch (err: any) {
      if (err.message === 'User already registered') {
        setError('Questa email è già registrata');
      } else {
        console.error('Errore durante la registrazione:', err);
        setError('Errore durante la registrazione');
      }
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="employeeCode" className="block text-sm font-medium text-gray-700">
          Codice Dipendente
        </label>
        <select
          id="employeeCode"
          value={employeeCode}
          onChange={(e) => setEmployeeCode(e.target.value)}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
          required
        >
          <option value="">Seleziona il tuo codice</option>
          {EMPLOYEE_CODES.map(code => (
            <option key={code} value={code}>{code}</option>
          ))}
        </select>
      </div>
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
      <div>
        <label htmlFor="password" className="block text-sm font-medium text-gray-700">
          Password
        </label>
        <input
          id="password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
          required
        />
      </div>
      {error && <p className="text-red-500 text-sm">{error}</p>}
      <button
        type="submit"
        className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      >
        Registrati
      </button>
    </form>
  );
}