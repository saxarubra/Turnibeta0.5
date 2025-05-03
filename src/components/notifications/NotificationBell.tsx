import { useState, useEffect } from 'react';
import { Bell, Check, X } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

type Notification = {
  id: string;
  message: string;
  read: boolean;
  created_at: string;
  swap_id?: string;
  shift_swaps?: {
    id: string;
    status: string;
    from_employee: string;
    to_employee: string;
    from_shift: string;
    to_shift: string;
    date: string;
  };
};

export function NotificationBell() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [isOpen, setIsOpen] = useState(false);
  const { user } = useAuth();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;
    
    loadNotifications();

    const channel = supabase
      .channel('notifications')
      .on(
        'postgres_changes',
        { 
          event: '*', 
          schema: 'public', 
          table: 'notifications',
          filter: `user_id=eq.${user.id}`
        },
        () => loadNotifications()
      )
      .subscribe();

    return () => {
      channel.unsubscribe();
    };
  }, [user]);

  const loadNotifications = async () => {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .select(`
          *,
          shift_swaps (
            id,
            status,
            from_employee,
            to_employee,
            from_shift,
            to_shift,
            date
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setNotifications(data || []);
      setUnreadCount(data.filter(n => !n.read).length);
    } catch (err) {
      console.error('Error loading notifications:', err);
    }
  };

  const markAsRead = async (id: string) => {
    await supabase
      .from('notifications')
      .update({ read: true })
      .eq('id', id);

    setNotifications(prev => 
      prev.map(n => n.id === id ? { ...n, read: true } : n)
    );
    setUnreadCount(prev => Math.max(0, prev - 1));
  };

  const handleSwapResponse = async (swapId: string, accept: boolean) => {
    try {
      const notification = notifications.find(n => n.shift_swaps?.id === swapId);
      const swap = notification?.shift_swaps;
      if (accept) {
        if (!swap || swap.status !== 'authorized') {
          setError('Lo scambio deve essere prima autorizzato via email!');
          return;
        }
      }
      const { error } = await supabase
        .from('shift_swaps')
        .update({ status: accept ? 'accepted' : 'rejected' })
        .eq('id', swapId);

      if (error) throw error;
      await loadNotifications();
    } catch (err) {
      console.error('Error handling swap response:', err);
      setError('Errore nella gestione della risposta');
    }
  };

  const isSwapRequest = (notification: Notification) => {
    return notification.message.includes('Nuova richiesta di scambio');
  };

  const isPendingSwap = (notification: Notification) => {
    return notification.shift_swaps?.status === 'pending';
  };

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="relative p-2 text-gray-600 hover:text-gray-800 hover:bg-gray-100 rounded-full"
      >
        <Bell className="h-6 w-6" />
        {unreadCount > 0 && (
          <span className="absolute top-1 right-1 h-3 w-3 bg-red-500 rounded-full animate-pulse" />
        )}
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-96 bg-white rounded-lg shadow-lg z-50 border border-gray-200">
          <div className="p-4 border-b border-gray-200">
            <div className="flex justify-between items-center">
              <h3 className="text-lg font-medium">Notifiche</h3>
              {unreadCount > 0 && (
                <span className="text-sm text-gray-500">{unreadCount} non lette</span>
              )}
            </div>
          </div>
          <div className="max-h-[32rem] overflow-y-auto">
            {notifications.length > 0 ? (
              notifications.map((notification) => (
                <div
                  key={notification.id}
                  className={`p-4 border-b hover:bg-gray-50 ${
                    notification.read ? 'opacity-75' : ''
                  }`}
                >
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <p className="text-sm text-gray-800">{notification.message}</p>
                      <p className="text-xs text-gray-500 mt-1">
                        {new Date(notification.created_at).toLocaleString('it-IT')}
                      </p>
                    </div>
                    
                    {isSwapRequest(notification) && isPendingSwap(notification) && notification.shift_swaps && (
                      <div className="flex gap-2 ml-4">
                        <button
                          onClick={() => handleSwapResponse(notification.shift_swaps!.id, true)}
                          className="p-1 text-green-600 hover:bg-green-50 rounded"
                          title="Accetta scambio"
                        >
                          <Check className="h-5 w-5" />
                        </button>
                        <button
                          onClick={() => handleSwapResponse(notification.shift_swaps!.id, false)}
                          className="p-1 text-red-600 hover:bg-red-50 rounded"
                          title="Rifiuta scambio"
                        >
                          <X className="h-5 w-5" />
                        </button>
                      </div>
                    )}
                  </div>
                  
                  {!notification.read && (
                    <button
                      onClick={() => markAsRead(notification.id)}
                      className="text-xs text-indigo-600 hover:text-indigo-800 mt-2"
                    >
                      Segna come letta
                    </button>
                  )}
                </div>
              ))
            ) : (
              <p className="p-4 text-center text-gray-500">Nessuna notifica</p>
            )}
          </div>
          {error && (
            <div className="bg-red-50 text-red-700 p-2 text-sm rounded mb-2">{error}</div>
          )}
        </div>
      )}
    </div>
  );
}