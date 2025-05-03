import React, { useState } from 'react';
import { Upload } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

interface ShiftData {
  employee_code: string;
  sunday_shift?: string;
  monday_shift?: string;
  tuesday_shift?: string;
  wednesday_shift?: string;
  thursday_shift?: string;
  friday_shift?: string;
  saturday_shift?: string;
  [key: string]: string | undefined;
}

interface MatrixData {
  week_start_date: string;
  shifts: ShiftData[];
}

interface MultiWeekMatrixData {
  weeks: MatrixData[];
}

interface MatrixUploaderProps {
  onUploadComplete: (date: string) => void;
}

export function MatrixUploader({ onUploadComplete }: MatrixUploaderProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [uploadProgress, setUploadProgress] = useState<number>(0);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const { user } = useAuth();

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files;
    if (!files || files.length === 0) return;

    setIsLoading(true);
    setError(null);
    setUploadProgress(0);
    setSuccessMessage(null);

    try {
      // Leggi tutti i file JSON
      const jsonDataArray: MatrixData[] = [];
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        if (file.type === 'application/json') {
          const text = await file.text();
          const jsonData = JSON.parse(text);
          if (validateMatrixData(jsonData)) {
            jsonDataArray.push(jsonData);
          } else {
            throw new Error(`Formato non valido nel file ${file.name}`);
          }
        } else {
          throw new Error(`Il file ${file.name} non è un file JSON valido`);
        }
      }

      // Ordina le settimane per data
      jsonDataArray.sort((a, b) => 
        new Date(a.week_start_date).getTime() - new Date(b.week_start_date).getTime()
      );

      // Crea l'oggetto multi-settimana
      const multiWeekData: MultiWeekMatrixData = {
        weeks: jsonDataArray
      };

      // Carica tutte le settimane
      await handleMultiWeekUpload(multiWeekData);
      setSuccessMessage(`Caricate ${jsonDataArray.length} settimane con successo!`);
      
      // Usa la data dell'ultima settimana caricata per il callback
      const lastWeekDate = jsonDataArray[jsonDataArray.length - 1].week_start_date;
      
      // Forza il ricaricamento della pagina dopo il caricamento
      setTimeout(() => {
        window.location.reload();
      }, 1500);
      
      onUploadComplete(lastWeekDate);
    } catch (err) {
      console.error('Error uploading files:', err);
      setError(err instanceof Error ? err.message : 'Errore durante il caricamento dei file');
    } finally {
      setIsLoading(false);
    }
  };

  const handleMultiWeekUpload = async (data: MultiWeekMatrixData) => {
    if (!validateMultiWeekMatrixData(data)) {
      throw new Error('Formato dati non valido. Controlla il formato dei file.');
    }

    const totalWeeks = data.weeks.length;
    let completedWeeks = 0;

    for (const weekData of data.weeks) {
      try {
        // Verifica se esiste già una matrice per questa data
        const { data: existingData, error: checkError } = await supabase
          .from('shifts_schedule')
          .select('id')
          .eq('week_start_date', weekData.week_start_date)
          .limit(1);

        if (checkError) throw checkError;

        // Se esiste già una matrice per questa data, elimina i dati esistenti
        if (existingData && existingData.length > 0) {
          const { error: deleteError } = await supabase
            .from('shifts_schedule')
            .delete()
            .eq('week_start_date', weekData.week_start_date);

          if (deleteError) throw deleteError;
        }

        // Inserisci i nuovi dati
        const { error } = await supabase
          .from('shifts_schedule')
          .insert(weekData.shifts.map(shift => ({
            ...shift,
            week_start_date: weekData.week_start_date
          })));

        if (error) throw error;
        
        completedWeeks++;
        setUploadProgress(Math.round((completedWeeks / totalWeeks) * 100));
      } catch (err) {
        console.error(`Error uploading week ${weekData.week_start_date}:`, err);
        throw new Error(`Errore durante il caricamento della settimana ${weekData.week_start_date}: ${err instanceof Error ? err.message : 'Errore sconosciuto'}`);
      }
    }
  };

  const validateMultiWeekMatrixData = (data: any): boolean => {
    if (!data || typeof data !== 'object') return false;
    if (!data.weeks || !Array.isArray(data.weeks)) return false;
    if (data.weeks.length === 0) return false;

    return data.weeks.every((week: any) => validateMatrixData(week));
  };

  const validateMatrixData = (data: any): boolean => {
    if (!data || typeof data !== 'object') return false;
    if (!data.week_start_date || !Array.isArray(data.shifts)) return false;
    if (data.shifts.length === 0) return false;

    return data.shifts.every((shift: any) => 
      shift.employee_code &&
      typeof shift.employee_code === 'string' &&
      ['sunday_shift', 'monday_shift', 'tuesday_shift', 
       'wednesday_shift', 'thursday_shift', 'friday_shift', 
       'saturday_shift'].every(day => 
        !shift[day] || typeof shift[day] === 'string'
      )
    );
  };

  // If not admin, don't render the uploader
  if (user?.user_metadata?.full_name !== 'ADMIN') {
    return (
      <div className="p-4 bg-red-50 rounded-md">
        <p className="text-sm text-red-700">
          Solo gli amministratori possono caricare la matrice dei turni
        </p>
      </div>
    );
  }

  return (
    <div className="p-4 bg-white rounded-lg shadow">
      <div className="flex flex-col items-center space-y-4">
        <label className="w-full max-w-xl flex flex-col items-center px-4 py-6 bg-white rounded-lg border-2 border-dashed border-gray-300 cursor-pointer hover:border-gray-400">
          <Upload className="w-8 h-8 text-gray-400" />
          <span className="mt-2 text-base text-gray-600">
            {isLoading ? 'Caricamento...' : 'Seleziona uno o più file JSON'}
          </span>
          <input
            type="file"
            className="hidden"
            accept=".json"
            onChange={handleFileChange}
            disabled={isLoading}
            multiple
          />
        </label>

        {isLoading && (
          <div className="w-full max-w-xl">
            <div className="w-full bg-gray-200 rounded-full h-2.5">
              <div className="bg-blue-600 h-2.5 rounded-full" style={{ width: `${uploadProgress}%` }}></div>
            </div>
            <p className="text-sm text-gray-600 mt-1">Progresso: {uploadProgress}%</p>
          </div>
        )}

        {error && (
          <div className="w-full max-w-xl p-4 text-red-700 bg-red-100 rounded">
            {error}
          </div>
        )}

        {successMessage && (
          <div className="w-full max-w-xl p-4 text-green-700 bg-green-100 rounded">
            {successMessage}
          </div>
        )}

        <div className="w-full max-w-xl mt-4">
          <h3 className="text-lg font-semibold mb-2">Formato JSON richiesto:</h3>
          <p className="text-sm text-gray-600 mb-2">
            Puoi selezionare più file JSON contemporaneamente. Ogni file deve contenere una settimana di turni.
          </p>
          <pre className="bg-gray-100 p-4 rounded text-sm overflow-auto">
{`{
  "week_start_date": "2023-06-01",
  "shifts": [
    {
      "employee_code": "CA",
      "sunday_shift": "RI",
      "monday_shift": "8.00",
      "tuesday_shift": "05.55+",
      "wednesday_shift": "05.55",
      "thursday_shift": "06.30",
      "friday_shift": "05.55",
      "saturday_shift": "NL"
    },
    ...
  ]
}`}
          </pre>
        </div>
      </div>
    </div>
  );
}