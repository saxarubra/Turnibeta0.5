// Test di connessione a Supabase
const supabaseUrl = 'https://llfdsyejuhfbaujjzofw.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsZmRzeWVqdWhmYmF1amp6b2Z3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYxOTA1MzgsImV4cCI6MjA1MTc2NjUzOH0.wwEmTIP8KIo9Z9B0rp8FfuxAM4OonaHoxY7oWNQX88M';

console.log('Test di connessione a Supabase...');
console.log('URL:', supabaseUrl);
console.log('Chiave:', supabaseKey.substring(0, 10) + '...');

// Funzione per testare la connessione
async function testConnection() {
  try {
    // Test 1: Verifica se le variabili d'ambiente sono caricate
    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Variabili d\'ambiente mancanti: VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY');
    }
    
    console.log('Variabili d\'ambiente caricate correttamente');
    
    // Test 2: Prova a recuperare i dati dalla tabella users
    console.log('Recupero dati dalla tabella users...');
    
    // Utilizziamo fetch per testare la connessione senza dipendere da @supabase/supabase-js
    const response = await fetch(`${supabaseUrl}/rest/v1/users?select=*&limit=5`, {
      headers: {
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      }
    });
    
    if (!response.ok) {
      throw new Error(`Errore HTTP: ${response.status} ${response.statusText}`);
    }
    
    const data = await response.json();
    console.log('Connessione riuscita! Dati recuperati con successo:');
    console.log(JSON.stringify(data, null, 2));
  } catch (err) {
    console.error('Errore di connessione:', err);
  }
}

// Esegui il test
testConnection(); 