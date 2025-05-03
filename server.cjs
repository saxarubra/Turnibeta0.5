require('dotenv').config();
console.log('DEBUG - VITE_RESEND_API_KEY:', process.env.VITE_RESEND_API_KEY);
console.log('DEBUG - RESEND_API_KEY:', process.env.RESEND_API_KEY);
const express = require('express');
const cors = require('cors');
const sendSwapEmail = require('./api/send-swap-email.cjs');
const { supabase } = require('./src/lib/supabase.cjs');
const app = express();
const PORT = 4000;

// Middleware
app.use(cors());
app.use(express.json());

// Abilita il logging delle richieste
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

app.post('/api/send-swap-email', async (req, res) => {
  console.log('*** LOG PERSONALIZZATO: Ricevuta richiesta di invio email ***');
  console.log('Ricevuta richiesta di invio email:', JSON.stringify(req.body, null, 2));
  try {
    await sendSwapEmail(req, res);
  } catch (error) {
    console.error('Errore nel server:', error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/swaps/:swapId/authorize', async (req, res) => {
  console.log('--- AUTORIZZAZIONE CHIAMATA ---', req.params.swapId);

  // Logga tutti gli id presenti
  try {
    const { data: allSwaps, error: allSwapsError } = await supabase
      .from('shift_swaps')
      .select('id');
    if (allSwapsError) {
      console.error('Errore nel recupero di tutti gli id:', allSwapsError);
    } else {
      console.log('Tutti gli id:', allSwaps.map(s => s.id), 'lunghezze:', allSwaps.map(s => s.id.length));
    }
  } catch (e) {
    console.error('Errore inatteso nel log degli id:', e);
  }

  const swapId = req.params.swapId;
  console.log('swapId ricevuto:', swapId, 'lunghezza:', swapId.length);
  // Prova ad aggiornare lo stato
  const { data, error } = await supabase
    .from('shift_swaps')
    .update({ status: 'authorized' })
    .eq('id', swapId)
    .eq('status', 'pending')
    .select();

  if (!data || data.length === 0) {
    // Fai una select per vedere se lo swap esiste ma ha già status 'authorized'
    const { data: swap, error: selectError } = await supabase
      .from('shift_swaps')
      .select('status')
      .eq('id', swapId)
      .single();
    console.log('Risultato select di controllo:', { swap, selectError });
    if (swap && swap.status === 'authorized') {
      return res.send('<h2>Scambio già autorizzato!</h2>');
    }
    if (swap && swap.status === 'accepted') {
      return res.send('<h2>Scambio già accettato!</h2>');
    }
    console.error('Nessuno swap aggiornato, id non trovato:', swapId);
    return res.status(404).send('<h2>Scambio non trovato.</h2>');
  }

  res.send('<h2>Scambio autorizzato con successo!</h2>');
});

app.get('/api/swaps/:swapId/reject', async (req, res) => {
  const swapId = req.params.swapId;
  console.log('--- RIFIUTO CHIAMATO ---', swapId);

  try {
    const { data: allSwaps, error: allSwapsError } = await supabase
      .from('shift_swaps')
      .select('id, status');
    if (allSwapsError) {
      console.error('Errore nel recupero di tutti gli id:', allSwapsError);
    } else {
      console.log('Tutti gli id e status:', allSwaps.map(s => `${s.id}:${s.status}`));
    }
  } catch (e) {
    console.error('Errore inatteso nel log degli id:', e);
  }

  // Prova ad aggiornare lo stato a 'rejected' se è pending o authorized
  const { data, error } = await supabase
    .from('shift_swaps')
    .update({ status: 'rejected' })
    .eq('id', swapId)
    .in('status', ['pending', 'authorized'])
    .select();

  if (!data || data.length === 0) {
    // Fai una select per vedere se lo swap esiste e il suo stato attuale
    const { data: swap, error: selectError } = await supabase
      .from('shift_swaps')
      .select('status')
      .eq('id', swapId)
      .single();
    console.log('Risultato select di controllo:', { swap, selectError });
    if (swap && swap.status === 'rejected') {
      return res.send('<h2>Scambio già rifiutato!</h2>');
    }
    if (swap && swap.status === 'accepted') {
      return res.send('<h2>Scambio già accettato!</h2>');
    }
    return res.status(404).send('<h2>Scambio non trovato o già gestito.</h2>');
  }

  res.send('<h2>Scambio rifiutato con successo!</h2>');
});

app.get('/api/debug/:swapId', async (req, res) => {
  const swapId = req.params.swapId;
  const { data, error } = await supabase
    .from('shift_swaps')
    .select('*')
    .eq('id', swapId)
    .single();
  res.json({ data, error });
});

app.listen(PORT, () => {
  console.log(`API Server running on port ${PORT}`);
  console.log('Variabili d\'ambiente disponibili:');
  console.log('VITE_RESEND_API_KEY:', process.env.VITE_RESEND_API_KEY ? 'Presente' : 'Mancante');
  console.log('VITE_EMAIL_FROM:', process.env.VITE_EMAIL_FROM || 'Non configurato');
  console.log('*** BACKEND PARTITO QUI ***');
  // Stampa le route registrate
  if (app._router && app._router.stack) {
    console.log('--- ROUTES REGISTRATE ---');
    app._router.stack.forEach(r => r.route && console.log(r.route.path));
    console.log('-------------------------');
  }
  console.log('SERVER AVVIATO!!!');
});