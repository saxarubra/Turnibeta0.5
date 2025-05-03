export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      notifications: {
        Row: {
          created_at: string | null
          id: string
          message: string
          read: boolean | null
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          message: string
          read?: boolean | null
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          message?: string
          read?: boolean | null
          user_id?: string
        }
        Relationships: []
      }
      shift_swaps: {
        Row: {
          created_at: string | null
          date: string
          from_employee: string
          from_shift: string
          id: string
          status: string
          to_employee: string
          to_shift: string
        }
        Insert: {
          created_at?: string | null
          date: string
          from_employee: string
          from_shift: string
          id?: string
          status?: string
          to_employee: string
          to_shift: string
        }
        Update: {
          created_at?: string | null
          date?: string
          from_employee?: string
          from_shift?: string
          id?: string
          status?: string
          to_employee?: string
          to_shift?: string
        }
        Relationships: []
      }
      shifts_schedule: {
        Row: {
          created_at: string | null
          display_order: number | null
          employee_code: string
          friday_shift: string | null
          id: string
          monday_shift: string | null
          saturday_shift: string | null
          sunday_shift: string | null
          thursday_shift: string | null
          tuesday_shift: string | null
          wednesday_shift: string | null
          week_start_date: string
        }
        Insert: {
          created_at?: string | null
          display_order?: number | null
          employee_code: string
          friday_shift?: string | null
          id?: string
          monday_shift?: string | null
          saturday_shift?: string | null
          sunday_shift?: string | null
          thursday_shift?: string | null
          tuesday_shift?: string | null
          wednesday_shift?: string | null
          week_start_date: string
        }
        Update: {
          created_at?: string | null
          display_order?: number | null
          employee_code?: string
          friday_shift?: string | null
          id?: string
          monday_shift?: string | null
          saturday_shift?: string | null
          sunday_shift?: string | null
          thursday_shift?: string | null
          tuesday_shift?: string | null
          wednesday_shift?: string | null
          week_start_date?: string
        }
        Relationships: []
      }
      users: {
        Row: {
          created_at: string | null
          email: string | null
          full_name: string | null
          id: string
          role: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          email?: string | null
          full_name?: string | null
          id: string
          role?: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          email?: string | null
          full_name?: string | null
          id?: string
          role?: string
          updated_at?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      accept_swap_chain: {
        Args: { swap_id: string }
        Returns: undefined
      }
      cancella_utente: {
        Args: { id_utente: string }
        Returns: undefined
      }
      cancella_utente_semplice: {
        Args: { id_utente: string }
        Returns: undefined
      }
      create_shift_time: {
        Args: { shift_date: string; shift_time: string }
        Returns: string
      }
      delete_auth_user: {
        Args: { user_id: string }
        Returns: undefined
      }
      delete_user: {
        Args: { user_id: string }
        Returns: undefined
      }
      delete_user_auth: {
        Args: { user_id: string }
        Returns: undefined
      }
      get_or_create_user: {
        Args: { p_email: string; p_full_name: string }
        Returns: string
      }
      get_shift_at_day: {
        Args: { shifts: string[]; day_index: number }
        Returns: string
      }
      parse_shift_time: {
        Args: { shift_time: string; base_date: string }
        Returns: string[]
      }
      reset_admin_swaps: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      reset_all_tables: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      reset_database: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      shift_type: {
        code: string | null
        time: string | null
        location: string | null
      }
    }
  }
}

type DefaultSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof Database },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof Database }
  ? Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const

export interface Notification {
  id: string;
  user_id: string;
  message: string;
  type: string;
  read: boolean;
  created_at: string;
  shift_swaps?: {
    id: string;
    status: string;
    from_employee: string;
    to_employee: string;
    from_shift: string;
    to_shift: string;
    date: string;
  };
}

export interface SwapRecord {
  id: string;
  date: string;
  from_employee: string;
  to_employee: string;
  from_shift: string;
  to_shift: string;
  status: string;
  created_at: string;
}
