import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import ShiftList from './components/shifts/ShiftList';
import { SwapsPage } from './components/shifts/SwapsPage';
import './App.css';
import { LoginForm } from './components/auth/LoginForm';
import { SignUpForm } from './components/auth/SignUpForm';
import { MatrixUploader } from './components/shifts/MatrixUploader';
import { LogOut, User, RefreshCw, ArrowLeftRight } from './lib/icons';
import { supabase } from './lib/supabase';
import Notifications from './components/Notifications';
import { AdminSetup } from './components/admin/AdminSetup';
import ResetPasswordPage from './components/auth/ResetPasswordPage';

export default function App() {
  const { user, loading, signOut } = useAuth();
  const [showPasswordReset, setShowPasswordReset] = useState(false);
  const [showMatrix, setShowMatrix] = useState(false);
  const [currentWeekStart, setCurrentWeekStart] = useState<string | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showSwapsPage, setShowSwapsPage] = useState(false);

  // Controlla se la pagina è /reset-password con type=recovery nell'hash
  const isRecovery = window.location.pathname === '/reset-password' && window.location.hash.includes('type=recovery');

  useEffect(() => {
    checkAdminStatus();
  }, [user]);

  useEffect(() => {
    if (user) {
      loadLatestSchedule();
    }
  }, [user]);

  const checkAdminStatus = async () => {
    if (!user) return;

    try {
      setError(null);
      const { data, error: supabaseError } = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

      if (supabaseError) {
        throw supabaseError;
      }

      setIsAdmin(data?.role === 'admin' || false);
    } catch (err: any) {
      console.error('Error checking admin status:', err);
      setError(err.message);
      setIsAdmin(false);
    }
  };

  const loadLatestSchedule = async () => {
    try {
      const { data, error } = await supabase
        .from('shifts_schedule')
        .select('week_start_date')
        .order('week_start_date', { ascending: false })
        .limit(1)
        .single();

      if (error) throw error;

      if (data) {
        setCurrentWeekStart(data.week_start_date);
        setShowMatrix(true);
      }
    } catch (err) {
      console.error('Error loading latest schedule:', err);
    }
  };

  const handleUploadSuccess = (date: string) => {
    setCurrentWeekStart(date);
    setShowMatrix(true);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <p className="text-gray-600">Loading...</p>
      </div>
    );
  }

  if (isRecovery) {
    // Mostra SEMPRE la pagina di reset password se siamo su /reset-password con token recovery
    return <ResetPasswordPage />;
  }

  return (
    <Router>
      <Routes>
        {/* Pagina di reset password sempre accessibile */}
        <Route path="/reset-password" element={<ResetPasswordPage />} />
        {/* Login e signup nella stessa pagina */}
        <Route path="/login" element={
          user ? <Navigate to="/" /> : (
            <div className="min-h-screen flex items-center justify-center bg-gray-100">
              <div className="bg-white p-6 rounded-lg shadow-md w-full max-w-sm">
                <h2 className="text-2xl font-bold mb-6 text-center">Welcome</h2>
                <div className="space-y-6">
                  <LoginForm onForgotPassword={() => window.location.href = '/reset-password'} />
                  <div className="relative">
                    <div className="absolute inset-0 flex items-center">
                      <div className="w-full border-t border-gray-300" />
                    </div>
                    <div className="relative flex justify-center text-sm">
                      <span className="px-2 bg-white text-gray-500">Or sign up</span>
                    </div>
                  </div>
                  <SignUpForm />
                </div>
              </div>
            </div>
          )
        } />
        {/* Home page protetta: dashboard completa come prima */}
        <Route path="/" element={user ? (
          <div className="min-h-screen bg-gray-100">
            <nav className="bg-white shadow-sm">
              <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between h-16">
                  <div className="flex items-center">{/* Logo o titolo */}</div>
                  <div className="flex items-center">
                    <Notifications />
                    <button
                      onClick={() => setShowSwapsPage(true)}
                      className="ml-4 px-3 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600"
                    >
                      Scambi Turno
                    </button>
                    {isAdmin && (
                      <button
                        onClick={async () => {
                          if (!confirm('Sei sicuro di voler resettare il database? Questa azione cancellerà tutti i turni, gli scambi e le notifiche.')) {
                            return;
                          }
                          try {
                            // Cancella tutti i dati dalla tabella shifts_schedule
                            const { error: shiftsError } = await supabase
                              .from('shifts_schedule')
                              .delete()
                              .neq('id', '00000000-0000-0000-0000-000000000000');
                            if (shiftsError) throw shiftsError;
                            // Cancella tutti i dati dalla tabella shift_swaps
                            const { error: swapsError } = await supabase
                              .from('shift_swaps')
                              .delete()
                              .neq('id', '00000000-0000-0000-0000-000000000000');
                            if (swapsError) throw swapsError;
                            // Cancella tutti i dati dalla tabella notifications
                            const { error: notificationsError } = await supabase
                              .from('notifications')
                              .delete()
                              .neq('id', '00000000-0000-0000-0000-000000000000');
                            if (notificationsError) throw notificationsError;
                            alert('Database resettato con successo!');
                            window.location.reload();
                          } catch (err) {
                            alert('Errore durante il reset del database: ' + (err as Error).message);
                          }
                        }}
                        className="ml-4 px-3 py-2 bg-red-500 text-white rounded-md hover:bg-red-600"
                      >
                        Reset DB
                      </button>
                    )}
                    <button
                      onClick={() => signOut()}
                      className="ml-4 px-3 py-2 border border-gray-300 rounded-md text-gray-700 bg-white hover:bg-gray-50"
                    >
                      Sign Out
                    </button>
                  </div>
                </div>
              </div>
            </nav>
            <header className="bg-white shadow">
              <div className="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8">
                <div className="flex justify-between items-center">
                  <h1 className="text-xl font-semibold text-gray-900">Shift Management</h1>
                  <div className="flex items-center space-x-4">
                    <div className="flex items-center space-x-2 px-3 py-2 bg-indigo-50 rounded-md">
                      <span className="text-sm font-medium text-indigo-700">{user.user_metadata.full_name}</span>
                    </div>
                  </div>
                </div>
              </div>
            </header>
            {error && (
              <div className="max-w-7xl mx-auto px-4 py-2">
                <div className="bg-red-50 text-red-700 p-4 rounded-md mt-4">
                  {error}
                </div>
              </div>
            )}
            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
              <div className="mt-6">
                {isAdmin && !showMatrix ? (
                  <MatrixUploader onUploadComplete={handleUploadSuccess} />
                ) : (
                  <ShiftList initialDate={currentWeekStart} />
                )}
              </div>
              <div className="mt-8">
                <AdminSetup />
              </div>
            </main>
            {showSwapsPage && (
              <SwapsPage onClose={() => setShowSwapsPage(false)} />
            )}
          </div>
        ) : <Navigate to="/login" />} />
        {/* Catch-all */}
        <Route path="*" element={<Navigate to={user ? '/' : '/login'} />} />
      </Routes>
    </Router>
  );
}