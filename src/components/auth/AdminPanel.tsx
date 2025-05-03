import { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';
import { Trash2, AlertCircle, RefreshCw, Upload } from 'lucide-react';

interface AuthUser {
  id: string;
  email: string;
  created_at: string;
}

export function AdminPanel() {
  const [authUsers, setAuthUsers] = useState<AuthUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [isResetting, setIsResetting] = useState(false);
  const [isDeletingSwaps, setIsDeletingSwaps] = useState(false);
  const { user } = useAuth();

  useEffect(() => {
    checkAdminStatus();
  }, [user]);

  const checkAdminStatus = async () => {
    if (!user) return;

    try {
      const { data, error } = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

      if (error) throw error;
      
      setIsAdmin(data?.role === 'admin');

      if (data?.role === 'admin') {
        loadAuthUsers();
      }
    } catch (err) {
      console.error('Error checking admin status:', err);
      setError('Errore nella verifica dello stato di amministratore');
    }
  };

  const loadAuthUsers = async () => {
    try {
      const { data, error } = await supabase
        .rpc('get_orphaned_auth_users');

      if (error) throw error;

      setAuthUsers(data || []);
      setError(null);
    } catch (err) {
      console.error('Error loading users:', err);
      setError('Errore nel caricamento degli utenti');
    } finally {
      setLoading(false);
    }
  };

  const deleteAuthUser = async (userId: string) => {
    try {
      const { error } = await supabase
        .rpc('delete_auth_user', {
          user_id: userId
        });

      if (error) throw error;

      await loadAuthUsers();
      setError(null);
    } catch (err) {
      console.error('Error deleting user:', err);
      setError('Errore durante l\'eliminazione dell\'utente');
    }
  };

  const handleResetDatabase = async () => {
    if (!isAdmin) return;

    const confirmReset = window.confirm(
      'Sei sicuro di voler resettare il database? Questa azione eliminerà tutti i turni e gli scambi, ma manterrà i dati degli utenti. Questa azione non può essere annullata.'
    );

    if (!confirmReset) return;

    setIsResetting(true);
    try {
      // Delete all notifications
      const { error: notifError } = await supabase
        .from('notifications')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');

      if (notifError) throw notifError;

      // Delete all swaps
      const { error: swapsError } = await supabase
        .from('shift_swaps_v2')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');

      if (swapsError) throw swapsError;

      // Delete all shifts
      const { error: shiftsError } = await supabase
        .from('shifts_schedule')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000');

      if (shiftsError) throw shiftsError;

      alert('Database resettato con successo!');
      window.location.reload(); // Reload the page to show empty state
    } catch (error) {
      console.error('Error resetting database:', error);
      alert('Errore durante il reset del database');
    } finally {
      setIsResetting(false);
    }
  };

  const handleDeleteAllSwaps = async () => {
    if (!isAdmin) return;

    const confirmDelete = window.confirm(
      'Sei sicuro di voler eliminare tutti gli scambi in sospeso? Questa azione eliminerà solo gli scambi non ancora accettati.'
    );

    if (!confirmDelete) return;

    setIsDeletingSwaps(true);
    try {
      // Delete notifications for pending swaps
      const { error: notifError } = await supabase
        .from('notifications')
        .delete()
        .eq('type', 'swap_request');

      if (notifError) throw notifError;

      // Delete pending swaps
      const { error: swapsError } = await supabase
        .from('shift_swaps_v2')
        .delete()
        .eq('status', 'pending');

      if (swapsError) throw swapsError;

      alert('Scambi in sospeso eliminati con successo!');
    } catch (error) {
      console.error('Error deleting swaps:', error);
      alert('Errore durante l\'eliminazione degli scambi');
    } finally {
      setIsDeletingSwaps(false);
    }
  };

  if (!isAdmin) {
    return null;
  }

  if (loading) {
    return (
      <div className="p-4 bg-white rounded-lg shadow">
        <p className="text-gray-600">Caricamento...</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Admin Actions */}
      <div className="p-6 bg-white rounded-lg shadow-lg border border-gray-200">
        <h2 className="text-xl font-bold mb-6 text-gray-900">Azioni Amministratore</h2>
        <div className="flex gap-4">
          <button
            onClick={handleDeleteAllSwaps}
            disabled={isDeletingSwaps}
            className="flex-1 inline-flex items-center justify-center px-6 py-3 border border-red-300 shadow-sm text-base font-medium rounded-md text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50"
          >
            <Trash2 className="h-5 w-5 mr-3" />
            Elimina scambi in sospeso
          </button>
          <button
            onClick={handleResetDatabase}
            disabled={isResetting}
            className="flex-1 inline-flex items-center justify-center px-6 py-3 border border-red-300 shadow-sm text-base font-medium rounded-md text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50"
          >
            <RefreshCw className={`h-5 w-5 mr-3 ${isResetting ? 'animate-spin' : ''}`} />
            Reset Database
          </button>
        </div>
      </div>

      {/* Orphaned Users */}
      <div className="p-4 bg-white rounded-lg shadow">
        <h2 className="text-lg font-semibold mb-4">Gestione Utenti</h2>
        
        {error && (
          <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-md flex items-center gap-2">
            <AlertCircle className="h-5 w-5" />
            <p>{error}</p>
          </div>
        )}

        <div className="space-y-2">
          {authUsers.length === 0 ? (
            <p className="text-gray-600">Nessun account orfano trovato.</p>
          ) : (
            <>
              <p className="text-sm text-gray-600 mb-2">
                Account di autenticazione senza corrispondenza nella tabella utenti:
              </p>
              {authUsers.map(authUser => (
                <div 
                  key={authUser.id}
                  className="flex items-center justify-between p-3 bg-gray-50 rounded-md hover:bg-gray-100"
                >
                  <div>
                    <p className="text-sm font-medium">{authUser.email}</p>
                    <p className="text-xs text-gray-500">
                      Creato il: {new Date(authUser.created_at).toLocaleDateString('it-IT')}
                    </p>
                  </div>
                  <button
                    onClick={() => {
                      if (window.confirm('Sei sicuro di voler eliminare questo account?')) {
                        deleteAuthUser(authUser.id);
                      }
                    }}
                    className="p-2 text-red-600 hover:bg-red-100 rounded-full transition-colors"
                    title="Elimina account"
                  >
                    <Trash2 className="h-5 w-5" />
                  </button>
                </div>
              ))}
            </>
          )}
        </div>
      </div>
    </div>
  );
}