import React, { useState, useEffect } from 'react';
import { Check, X, ChevronLeft, ChevronRight, ArrowLeftRight } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import PDFExport from './PDFExport';
import { PDFDocument } from 'pdf-lib';
import { format, addDays } from 'date-fns';
import { sendSwapRequestEmail } from '../../lib/emailService';

type Matrix = string[][];
type SwapRequest = {
  id: string;
  date: string;
  fromEmployee: string;
  toEmployee: string;
  fromShift: string;
  toShift: string;
  status: string;
  created_at?: string;
};

export default function ShiftList({ initialDate }: { initialDate?: string | null }) {
  const [matrix, setMatrix] = useState<Matrix>([]);
  const [selectedCells, setSelectedCells] = useState<[number, number][]>([]);
  const [swaps, setSwaps] = useState<SwapRequest[]>([]);
  const [currentWeekStart, setCurrentWeekStart] = useState(initialDate ? new Date(initialDate) : new Date());
  const [showUploader, setShowUploader] = useState(false);
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { user } = useAuth();
  const [uploadedJson, setUploadedJson] = useState<any>(null);
  const [availableWeeks, setAvailableWeeks] = useState<Date[]>([]);
  const [pendingSwap, setPendingSwap] = useState<{
    date: string;
    fromEmployee: string;
    toEmployee: string;
    fromShift: string;
    toShift: string;
    autoAccept: boolean;
  } | null>(null);

  const currentEmployeeCode = user?.user_metadata?.full_name;

  useEffect(() => {
    if (user) {
      checkAdminStatus();
      loadMatrix(currentWeekStart);
      loadSwaps();
      loadAvailableWeeks();

      const intervalId = setInterval(() => {
        loadSwaps();
        loadMatrix(currentWeekStart);
      }, 5000);

      const channel = supabase.channel('realtime-shifts')
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'shift_swaps',
          },
          async () => {
            await loadSwaps();
            await loadMatrix(currentWeekStart);
          }
        )
        .subscribe();

      return () => {
        channel.unsubscribe();
        clearInterval(intervalId);
      };
    }
  }, [user, currentWeekStart]);

  const checkAdminStatus = async () => {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('role')
        .eq('id', user?.id)
        .maybeSingle();

      if (error) throw error;
      setIsAdmin(data?.role === 'admin' || false);
    } catch (err) {
      console.error('Error checking admin status:', err);
      setIsAdmin(false);
    }
  };

  const loadMatrix = async (startDate: Date) => {
    try {
      const formattedDate = startDate.toISOString().split('T')[0];
      const nextWeekDate = new Date(startDate);
      nextWeekDate.setDate(nextWeekDate.getDate() + 7);
      const formattedNextWeekDate = nextWeekDate.toISOString().split('T')[0];
      
      const { data: scheduleData, error } = await supabase
        .from('shifts_schedule')
        .select('*')
        .in('week_start_date', [formattedDate, formattedNextWeekDate])
        .order('week_start_date', { ascending: true })
        .order('display_order', { ascending: true });

      if (error) throw error;

      if (scheduleData && scheduleData.length > 0) {
        const weekDates = getWeekDates(startDate);
        const nextWeekDates = getWeekDates(nextWeekDate);
        const headerRow = ["", ...weekDates.map(d => d.full), "", ...nextWeekDates.map(d => d.full)];
        const daysRow = ["", ...weekDates.map(d => d.day), "", ...nextWeekDates.map(d => d.day)];
        
        const matrixData = scheduleData
          .filter(row => row.week_start_date === formattedDate)
          .map(row => [
            row.employee_code,
            row.sunday_shift || '',
            row.monday_shift || '',
            row.tuesday_shift || '',
            row.wednesday_shift || '',
            row.thursday_shift || '',
            row.friday_shift || '',
            row.saturday_shift || '',
            '', // Separatore tra le due settimane
            ...scheduleData
              .filter(r => r.week_start_date === formattedNextWeekDate && r.employee_code === row.employee_code)
              .map(r => [
                r.sunday_shift || '',
                r.monday_shift || '',
                r.tuesday_shift || '',
                r.wednesday_shift || '',
                r.thursday_shift || '',
                r.friday_shift || '',
                r.saturday_shift || ''
              ])[0] || Array(7).fill('')
          ]);

        setMatrix([headerRow, daysRow, ...matrixData]);
      } else {
        const { data: latestData, error: latestError } = await supabase
          .from('shifts_schedule')
          .select('week_start_date')
          .order('week_start_date', { ascending: false })
          .limit(1)
          .single();

        if (!latestError && latestData) {
          const newDate = new Date(latestData.week_start_date);
          setCurrentWeekStart(newDate);
          loadMatrix(newDate);
        } else {
          setMatrix([]);
        }
      }
    } catch (err) {
      console.error('Error loading matrix:', err);
      setError('Errore nel caricamento dei turni');
    }
  };

  const getWeekDates = (startDate: Date) => {
    const dates = [];
    const days = ['Dom', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab'];
    
    for (let i = 0; i < 7; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      dates.push({
        full: date.toLocaleDateString('it-IT'),
        day: days[i]
      });
    }
    return dates;
  };

  const navigateWeek = (direction: number) => {
    const newDate = new Date(currentWeekStart);
    newDate.setDate(newDate.getDate() + (direction * 7));
    setCurrentWeekStart(newDate);
  };

  const loadSwaps = async () => {
    try {
      const { data, error } = await supabase
        .from('shift_swaps')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      if (data) {
        setSwaps(data.map(swap => ({
          id: swap.id,
          date: swap.date,
          fromEmployee: swap.from_employee,
          toEmployee: swap.to_employee,
          fromShift: swap.from_shift,
          toShift: swap.to_shift,
          status: swap.status,
          created_at: swap.created_at
        })));
      }
    } catch (err) {
      console.error('Error loading swaps:', err);
    }
  };

  const getFinalShift = (row: number, col: number): string => {
    const date = matrix[0][col];
    const employeeCode = matrix[row][0];
    const baseShift = matrix[row][col];
    
    if (col === 0) return baseShift;

    const formattedDate = date.split('/').reverse().join('-');
    
    const swap = swaps.find(s => 
      s.status === 'accepted' && 
      s.date === formattedDate &&
      (s.fromEmployee === employeeCode || s.toEmployee === employeeCode)
    );

    if (!swap) return baseShift;

    if (swap.fromEmployee === employeeCode) {
      return swap.toShift;
    }

    return swap.fromShift;
  };

  // Funzione per trovare il turno valido precedente (non NL, RI, vuoto)
  const findPreviousValidShift = (employeeRow: number, dateIndex: number): string | null => {
    let idx = dateIndex - 1;
    while (idx > 0) {
      const shift = matrix[employeeRow][idx];
      if (shift && shift !== '' && shift !== 'NL' && shift !== 'RI') {
        return shift;
      }
      idx--;
    }
    return null;
  };

  // Funzione per calcolare l'orario di fine di un turno dato l'orario di inizio (formato "HH.MM")
  const calculateEndTime = (startTime: string): string => {
    const [hours, minutes] = startTime.split('.').map(Number);
    let totalMinutes = hours * 60 + minutes + 515; // 8h35m = 515 min
    const endHours = Math.floor(totalMinutes / 60) % 24;
    const endMinutes = totalMinutes % 60;
    return `${endHours.toString().padStart(2, '0')}.${endMinutes.toString().padStart(2, '0')}`;
  };

  // Funzione per calcolare le ore di stacco tra fine turno precedente e inizio nuovo turno
  const calculateRestHours = (endTime: string, startTime: string): number => {
    const [endH, endM] = endTime.split('.').map(Number);
    const [startH, startM] = startTime.split('.').map(Number);
    let diff = (startH * 60 + startM) - (endH * 60 + endM);
    if (diff < 0) diff += 24 * 60;
    return diff / 60;
  };

  // Estrai l'orario dal turno (es: "06.30" da "06.30+ G1T")
  const extractTime = (shift: string): string | null => {
    const match = shift.match(/\d{2}\.\d{2}/);
    return match ? match[0] : null;
  };

  // Funzione aggiornata: salta NL, RI e vuoti per il controllo PRIMA e DOPO
  const checkRestTime = (employeeCode: string, date: string, newShift: string): boolean => {
    const employeeRow = matrix.findIndex(row => row[0] === employeeCode);
    if (employeeRow === -1) return true;
    const dateIndex = matrix[0].findIndex(d => d === date);
    if (dateIndex === -1) return true;

    // --- CONTROLLO PRIMA ---
    let prevIndex = dateIndex - 1;
    let checkBefore = true;
    while (prevIndex > 0) {
      const prevShift = matrix[employeeRow][prevIndex];
      if (prevShift && prevShift !== '' && prevShift !== 'NL' && prevShift !== 'RI') {
        const prevStart = extractTime(prevShift);
        const newStart = extractTime(newShift);
        if (prevStart && newStart) {
          // Fine turno precedente
          const [ph, pm] = prevStart.split('.').map(Number);
          let endMinutes = ph * 60 + pm + 515;
          let endHours = Math.floor(endMinutes / 60) % 24;
          let endMins = endMinutes % 60;
          // Inizio nuovo turno
          const [nh, nm] = newStart.split('.').map(Number);
          let diff = (nh * 60 + nm) - (endHours * 60 + endMins);
          if (diff < 0) diff += 24 * 60;
          const restHours = diff / 60;
          console.log(`${employeeCode} (PRIMA): Fine turno precedente ${endHours}:${endMins}, Inizio nuovo turno ${nh}:${nm}, Ore di stacco: ${restHours}`);
          checkBefore = restHours >= 11;
        }
        break;
      }
      prevIndex--;
    }

    // --- CONTROLLO DOPO ---
    let nextIndex = dateIndex + 1;
    let checkAfter = true;
    while (nextIndex < matrix[0].length) {
      const nextShift = matrix[employeeRow][nextIndex];
      if (nextShift && nextShift !== '' && nextShift !== 'NL' && nextShift !== 'RI') {
        const newStart = extractTime(newShift);
        const nextStart = extractTime(nextShift);
        if (newStart && nextStart) {
          // Fine nuovo turno
          const [nh, nm] = newStart.split('.').map(Number);
          let endMinutes = nh * 60 + nm + 515;
          let endHours = Math.floor(endMinutes / 60) % 24;
          let endMins = endMinutes % 60;
          // Inizio turno successivo
          const [sh, sm] = nextStart.split('.').map(Number);
          let diff = (sh * 60 + sm) - (endHours * 60 + endMins);
          if (diff < 0) diff += 24 * 60;
          const restHours = diff / 60;
          console.log(`${employeeCode} (DOPO): Fine nuovo turno ${endHours}:${endMins}, Inizio turno successivo ${sh}:${sm}, Ore di stacco: ${restHours}`);
          checkAfter = restHours >= 11;
        }
        break;
      }
      nextIndex++;
    }

    return checkBefore && checkAfter;
  };

  const handleCellClick = (row: number, col: number) => {
    if (col === 0) return;
    setError(null);
    const employeeCode = matrix[row][0];
    const date = matrix[0][col];

    setSelectedCells(prev => {
      // Selezione prima cella
      if (prev.length === 0) {
        if (isAdmin || employeeCode === currentEmployeeCode) {
          return [[row, col]];
        }
        return prev;
      }
      // Selezione seconda cella (diversa dalla prima)
      if (prev.length === 1) {
        const [firstRow, firstCol] = prev[0];
        if (firstRow === row && firstCol === col) {
          return [];
        }
        // Solo admin può selezionare qualsiasi combinazione, utenti normali solo colonne diverse
        if (!isAdmin && firstCol !== col) {
          return prev;
        }
        const fromEmployee = matrix[firstRow][0];
        const toEmployee = matrix[row][0];
        const fromDate = matrix[0][firstCol];
        const toDate = matrix[0][col];
        const fromShift = getFinalShift(firstRow, firstCol);
        const toShift = getFinalShift(row, col);

        if (!isAdmin) {
          const hasEnoughRestFrom = checkRestTime(fromEmployee, fromDate, toShift);
          const hasEnoughRestTo = checkRestTime(toEmployee, toDate, fromShift);
          if (!hasEnoughRestFrom || !hasEnoughRestTo) {
            setError('Non è possibile effettuare lo scambio: non rispetta il minimo di 11 ore di stacco tra turni');
            return prev;
          }
        }

        setPendingSwap({
          date: fromDate,
          fromEmployee,
          toEmployee,
          fromShift,
          toShift,
          autoAccept: isAdmin
        });
        return [];
      }
      return prev;
    });
  };

  const createNotification = async (userId: string, message: string, type: string, swapId: string) => {
    try {
      await supabase.from('notifications').insert({
        user_id: userId,
        message,
        type,
        related_swap_id: swapId
      });
    } catch (error) {
      console.error('Error creating notification:', error);
    }
  };

  const handleSwapRequest = async (shiftId: string) => {
    try {
      const shift = swaps.find(s => s.id === shiftId);
      if (!shift) return;

      // Verifica se l'email è già stata inviata
      const { data: swapData, error: swapError } = await supabase
        .from('shift_swaps')
        .select('email_sent')
        .eq('id', shiftId)
        .single();

      if (swapError) {
        console.error('Errore nel recupero dello stato email:', swapError);
        return;
      }

      if (!swapData?.email_sent) {
        await sendSwapRequestEmail({
          swapId: shift.id,
          fromEmployee: shift.fromEmployee,
          toEmployee: shift.toEmployee,
          fromShift: shift.fromShift,
          toShift: shift.toShift,
          date: shift.date
        });
        console.log('Email inviata con successo');
      } else {
        console.log('Email già inviata per questo scambio');
      }
    } catch (error) {
      console.error('Errore nell\'invio dell\'email:', error);
    }
  };

  const handleSwapResponse = async (swapId: string, accept: boolean) => {
    if (isLoading) return;
    try {
      setIsLoading(true);
      setError(null);
      const swap = swaps.find(s => s.id === swapId);
      if (!swap) {
        setError('Scambio non trovato');
        return;
      }

      if (accept) {
        // Solo se accetti e lo stato è 'pending', puoi accettare (LP accetta, parte la mail)
        if (swap.status !== 'pending') {
          setError('Lo scambio non è più in attesa di accettazione!');
          return;
        }
        // Invia la mail per autorizzazione
        await sendSwapRequestEmail({
          swapId: swap.id,
          fromEmployee: swap.fromEmployee,
          toEmployee: swap.toEmployee,
          fromShift: swap.fromShift,
          toShift: swap.toShift,
          date: swap.date
        });
        console.log('Email inviata per autorizzazione dello scambio');
      } else {
        // Se rifiuta e lo stato è 'pending', aggiorna a 'rejected'
        if (swap.status !== 'pending') {
          setError('Lo scambio non è più in attesa di accettazione!');
          return;
        }
        const { error: updateError } = await supabase
          .from('shift_swaps')
          .update({ status: 'rejected' })
          .eq('id', swapId);
        if (updateError) throw updateError;
        console.log('Scambio rifiutato con successo');
      }

      await loadSwaps();
      await loadMatrix(currentWeekStart);
    } catch (err) {
      console.error('Error handling swap response:', err);
      setError('Errore nella gestione della risposta');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCancelSwap = async (swapId: string) => {
    if (isLoading) return;
    try {
      setIsLoading(true);
      setError(null);

      const { error: updateError } = await supabase
        .from('shift_swaps')
        .update({ status: 'cancelled' })
        .eq('id', swapId);

      if (updateError) throw updateError;
      await loadSwaps();
      await loadMatrix(currentWeekStart);
    } catch (err) {
      console.error('Error cancelling swap:', err);
      setError('Errore nella cancellazione dello scambio');
    } finally {
      setIsLoading(false);
    }
  };

  const getSwapForCell = (row: number, col: number) => {
    if (col === 0) return null;

    const date = matrix[0][col];
    const employeeCode = matrix[row][0];
    const currentShift = getFinalShift(row, col);

    return swaps.find(swap => 
      swap.status === 'pending' &&
      swap.date === date.split('/').reverse().join('-') &&
      ((swap.fromEmployee === employeeCode && swap.fromShift === currentShift) ||
       (swap.toEmployee === employeeCode && swap.toShift === currentShift))
    );
  };

  const formatDate = (dateStr: string) => {
    const [year, month, day] = dateStr.split('-');
    return `${day}/${month}/${year}`;
  };

  async function convertPdfToJson(file: File) {
    const arrayBuffer = await file.arrayBuffer();
    const pdfDoc = await PDFDocument.load(arrayBuffer);
    const pages = pdfDoc.getPages();
    const jsonData = { week_start_date: '', shifts: [] };

    pages.forEach((page) => {
      // Manually extract and parse text content from the page
      // This is a placeholder for actual parsing logic
      // jsonData.shifts.push({ employee_code: 'CA', ... });
    });

    return jsonData;
  }

  const handleJsonUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      const text = await file.text();
      const jsonData = JSON.parse(text);
      setUploadedJson(jsonData);
    }
  };

  const handlePdfUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      const jsonData = await convertPdfToJson(file);
      setUploadedJson(jsonData);
    }
  };

  const createSwapRequest = async (date: string, fromEmployee: string, toEmployee: string, fromShift: string, toShift: string) => {
    if (isLoading) {
      console.warn('Richiesta di swap ignorata perché già in corso');
      return;
    }
    try {
      setIsLoading(true);
      setError(null);
      console.log('Creazione richiesta di scambio:', { date, fromEmployee, toEmployee, fromShift, toShift });

      const formattedDate = date.split('/').reverse().join('-');
      console.log('Data formattata:', formattedDate);

      const { data, error: insertError } = await supabase
        .from('shift_swaps')
        .insert({
          date: formattedDate,
          from_employee: fromEmployee,
          to_employee: toEmployee,
          from_shift: fromShift,
          to_shift: toShift,
          status: 'pending'
        })
        .select()
        .single();

      if (insertError) {
        console.error('Errore durante l\'inserimento:', insertError);
        throw insertError;
      }
      console.log('Scambio creato con successo:', data);
      await loadSwaps();
    } catch (err) {
      console.error('Errore nella creazione della richiesta di scambio:', err);
      setError('Errore nella creazione della richiesta di scambio: ' + (err as Error).message);
    } finally {
      setIsLoading(false);
    }
  };

  const loadAvailableWeeks = async () => {
    try {
      const { data, error } = await supabase
        .from('shifts_schedule')
        .select('week_start_date')
        .order('week_start_date', { ascending: true });

      if (error) throw error;

      const weeks = data
        .map(item => new Date(item.week_start_date))
        .filter((date, index, self) => 
          self.findIndex(d => d.getTime() === date.getTime()) === index
        );

      setAvailableWeeks(weeks);
    } catch (err) {
      console.error('Error loading available weeks:', err);
    }
  };

  useEffect(() => {
    if (pendingSwap) {
      createSwapRequest(
        pendingSwap.date,
        pendingSwap.fromEmployee,
        pendingSwap.toEmployee,
        pendingSwap.fromShift,
        pendingSwap.toShift
      );
      setPendingSwap(null);
    }
  }, [pendingSwap]);

  return (
    <div className="space-y-8">
      <div className="bg-white p-4 rounded-lg shadow">
        <h3 className="text-lg font-semibold mb-2">Settimane disponibili:</h3>
        <div className="flex flex-wrap gap-2">
          {availableWeeks.map((week) => (
            <button
              key={week.getTime()}
              onClick={() => setCurrentWeekStart(week)}
              className={`px-3 py-1 rounded-full text-sm ${
                currentWeekStart.getTime() === week.getTime()
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 hover:bg-gray-200'
              }`}
            >
              {format(week, 'dd/MM/yyyy')}
            </button>
          ))}
        </div>
      </div>

      <div className="flex items-center justify-between bg-white p-4 rounded-lg shadow">
        <button
          onClick={() => navigateWeek(-1)}
          className="p-2 hover:bg-gray-100 rounded-full"
        >
          <ChevronLeft className="w-6 h-6" />
        </button>
        <div className="text-center">
          <h2 className="text-xl font-semibold">
            {format(currentWeekStart, 'dd/MM/yyyy')} - {format(addDays(currentWeekStart, 13), 'dd/MM/yyyy')}
          </h2>
          <p className="text-sm text-gray-500">Due settimane di turni</p>
        </div>
        <button
          onClick={() => navigateWeek(1)}
          className="p-2 hover:bg-gray-100 rounded-full"
        >
          <ChevronRight className="w-6 h-6" />
        </button>
      </div>

      {error && (
        <div className="bg-red-50 text-red-700 p-4 rounded-md">
          {error}
        </div>
      )}

      {showUploader && (
        <div className="mb-4 p-4 bg-gray-100 rounded">
          <h3 className="text-lg font-semibold mb-2">Carica Turni</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Carica JSON</label>
              <input
                type="file"
                accept=".json"
                onChange={handleJsonUpload}
                className="mt-1 block w-full"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Carica PDF</label>
              <input
                type="file"
                accept=".pdf"
                onChange={handlePdfUpload}
                className="mt-1 block w-full"
              />
            </div>
          </div>
        </div>
      )}

      <div className="overflow-x-auto">
        {matrix.length > 0 ? (
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                {matrix[1]?.map((day, index) => (
                  <th key={index} className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {day}
                  </th>
                ))}
              </tr>
              <tr>
                {matrix[0]?.map((date, index) => (
                  <th key={index} className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {date}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {matrix.slice(2).map((row, rowIndex) => (
                <tr key={rowIndex}>
                  {row.map((cell, colIndex) => {
                    const swap = getSwapForCell(rowIndex + 2, colIndex);
                    const isSelected = selectedCells.some(([r, c]) => r === rowIndex + 2 && c === colIndex);
                    const isCurrentUser = row[0] === currentEmployeeCode;
                    const finalShift = getFinalShift(rowIndex + 2, colIndex);

                    return (
                      <td
                        key={colIndex}
                        onClick={() => handleCellClick(rowIndex + 2, colIndex)}
                        className={`px-6 py-4 whitespace-nowrap relative ${
                          colIndex === 0 ? 'font-medium text-gray-900' : 'text-gray-500'
                        } cursor-pointer ${isSelected ? 'bg-yellow-100' : ''} ${
                          isCurrentUser || isAdmin ? 'hover:bg-gray-50' : ''
                        }`}
                      >
                        {swap ? (
                          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-2">
                            <div className="font-medium">{finalShift}</div>
                            <div className="text-xs text-yellow-600">
                              {swap.toEmployee === row[0] ? (
                                <div className="flex items-center gap-2">
                                  <span>Richiesta da {swap.fromEmployee}</span>
                                  <div className="flex gap-1">
                                    <button
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        handleSwapResponse(swap.id, true);
                                      }}
                                      className="p-1 hover:bg-green-100 rounded disabled:opacity-50"
                                      disabled={isLoading}
                                      title="Accetta scambio"
                                    >
                                      <Check className="h-4 w-4 text-green-600" />
                                    </button>
                                    <button
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        handleSwapResponse(swap.id, false);
                                      }}
                                      className="p-1 hover:bg-red-100 rounded disabled:opacity-50"
                                      disabled={isLoading}
                                      title="Rifiuta scambio"
                                    >
                                      <X className="h-4 w-4 text-red-600" />
                                    </button>
                                  </div>
                                </div>
                              ) : (
                                <div className="flex items-center justify-between">
                                  <span>In attesa di {swap.toEmployee}</span>
                                  <button
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      handleCancelSwap(swap.id);
                                    }}
                                    className="p-1 hover:bg-red-100 rounded disabled:opacity-50"
                                    disabled={isLoading}
                                    title="Annulla richiesta"
                                  >
                                    <X className="h-4 w-4 text-red-600" />
                                  </button>
                                </div>
                              )}
                            </div>
                          </div>
                        ) : (
                          <div>{finalShift}</div>
                        )}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div className="text-center py-8 text-gray-500">
            Nessun turno disponibile. Carica una nuova matrice.
          </div>
        )}
      </div>

      <PDFExport matrix={matrix} />

      {/* Storico Scambi */}
      <div className="mt-8 bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-bold text-gray-800 mb-4">Storico Cambi Turno</h2>
        <div className="space-y-4">
          {swaps.map((swap) => (
            <div
              key={swap.id}
              className="bg-gray-50 p-4 rounded-lg flex items-center space-x-3"
            >
              <ArrowLeftRight className="h-5 w-5 text-gray-400 flex-shrink-0" />
              <div className="flex-1">
                <p className="text-sm text-gray-900">
                  <span className="font-medium">{swap.fromEmployee}</span>
                  {' ('}{swap.fromShift}{') '}
                  <span className="text-gray-500">ha scambiato con</span>
                  {' '}
                  <span className="font-medium">{swap.toEmployee}</span>
                  {' ('}{swap.toShift}{')'}
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  <span className="font-medium">Data turno:</span> {formatDate(swap.date)} - 
                  <span className="font-medium ml-2">Richiesto il:</span> {swap.created_at && new Date(swap.created_at).toLocaleDateString('it-IT')} alle{' '}
                  {swap.created_at && new Date(swap.created_at).toLocaleTimeString('it-IT')}
                  {' - Stato: '}
                  <span className={`font-medium ${
                      swap.status === 'accepted' ? 'text-green-600' :
                      swap.status === 'rejected' ? 'text-red-600' :
                      swap.status === 'cancelled' ? 'text-gray-600' :
                      'text-yellow-600'
                    }`}>
                    {swap.status === 'accepted' ? 'Accettato' :
                     swap.status === 'rejected' ? 'Rifiutato' :
                     swap.status === 'cancelled' ? 'Annullato' :
                     'In attesa'}
                  </span>
                </p>
              </div>
            </div>
          ))}
          
          {swaps.length === 0 && (
            <p className="text-center text-gray-500 py-4">Nessun cambio turno registrato</p>
          )}
        </div>
      </div>
    </div>
  );
}