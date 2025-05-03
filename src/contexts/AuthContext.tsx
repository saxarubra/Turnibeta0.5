import { createContext, useContext, useEffect, useState } from 'react';
import { User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, employeeCode: string) => Promise<void>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Initialize auth state
    const initAuth = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        setUser(session?.user ?? null);
      } catch (error) {
        console.error('Error initializing auth:', error);
        setUser(null);
      } finally {
        setLoading(false);
      }
    };

    initAuth();

    // Listen for auth state changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const signIn = async (email: string, password: string) => {
    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      
      // Verifica se l'utente esiste nella tabella users
      const { data: userData, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', (await supabase.auth.getUser()).data.user?.id)
        .maybeSingle();
        
      if (userError) {
        console.error('Error fetching user data:', userError);
        throw new Error('Errore durante il recupero dei dati utente');
      }
      
      if (!userData) {
        // Se l'utente non esiste nella tabella users, crealo
        const userFullName = (await supabase.auth.getUser()).data.user?.user_metadata?.full_name;
        const userEmail = (await supabase.auth.getUser()).data.user?.email;
        
        // Assegna il ruolo admin solo se l'email è admin@rai.it
        const isAdmin = userEmail === 'admin@rai.it';
        
        const { error: insertError } = await supabase
          .from('users')
          .insert({
            id: (await supabase.auth.getUser()).data.user?.id,
            full_name: userFullName,
            role: isAdmin ? 'admin' : 'user'
          });
          
        if (insertError) {
          console.error('Error creating user record:', insertError);
          throw new Error('Errore durante la creazione del profilo utente');
        }
      } else {
        // Se l'utente esiste già, verifica se è admin@rai.it e aggiorna il ruolo se necessario
        const userEmail = (await supabase.auth.getUser()).data.user?.email;
        const isAdmin = userEmail === 'admin@rai.it';
        
        if (isAdmin && userData.role !== 'admin') {
          // Aggiorna il ruolo a admin se l'email è admin@rai.it
          const { error: updateError } = await supabase
            .from('users')
            .update({ role: 'admin' })
            .eq('id', userData.id);
            
          if (updateError) {
            console.error('Error updating user role:', updateError);
          }
        } else if (!isAdmin && userData.role === 'admin') {
          // Rimuovi il ruolo admin se l'email non è admin@rai.it
          const { error: updateError } = await supabase
            .from('users')
            .update({ role: 'user' })
            .eq('id', userData.id);
            
          if (updateError) {
            console.error('Error updating user role:', updateError);
          }
        }
      }
    } catch (error: any) {
      console.error('Sign in error:', error);
      throw error;
    }
  };

  const signUp = async (email: string, password: string, employeeCode: string) => {
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: employeeCode
        }
      }
    });
    if (error) throw error;
  };

  const clearLocalAuth = () => {
    setUser(null);
    localStorage.removeItem('sb-auth-token');
  };

  const signOut = async () => {
    try {
      // Clear local state first to ensure the user appears signed out immediately
      clearLocalAuth();
      
      // Attempt to sign out from Supabase
      const { error } = await supabase.auth.signOut();
      if (error) {
        // If the error is due to user not found or session not found, we can safely ignore it
        // since we've already cleared the local state
        if (error.message === 'User from sub claim in JWT does not exist' ||
            error.message === 'Session from session_id claim in JWT does not exist') {
          return;
        }
        throw error;
      }
    } catch (error: any) {
      console.error('Sign out error:', error);
      // Since we've already cleared local state, we don't need to rethrow
      // as the user is effectively signed out from the application's perspective
    }
  };

  const resetPassword = async (email: string) => {
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`,
      });
      if (error) throw error;
    } catch (error: any) {
      console.error('Password reset error:', error);
      throw error;
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, signIn, signUp, signOut, resetPassword }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};