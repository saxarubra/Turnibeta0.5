import { useEffect } from 'react';
import { supabase } from '../../lib/supabase';

export function AdminSetup() {
  useEffect(() => {
    const setupAdmin = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (user?.email === 'admin@rai.it') {
        const { error } = await supabase
          .from('users')
          .upsert({ 
            id: user.id,
            email: user.email,
            role: 'admin'
          });

        if (error) {
          console.error('Error setting up admin:', error);
        }
      }
    };

    setupAdmin();
  }, []);

  return null;
} 