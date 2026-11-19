export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      admin_audit_logs: {
        Row: {
          action: string
          admin_id: string | null
          after: Json | null
          before: Json | null
          created_at: string
          id: number
          ip: unknown
          target_id: string | null
          target_table: string | null
        }
        Insert: {
          action: string
          admin_id?: string | null
          after?: Json | null
          before?: Json | null
          created_at?: string
          id?: never
          ip?: unknown
          target_id?: string | null
          target_table?: string | null
        }
        Update: {
          action?: string
          admin_id?: string | null
          after?: Json | null
          before?: Json | null
          created_at?: string
          id?: never
          ip?: unknown
          target_id?: string | null
          target_table?: string | null
        }
        Relationships: []
      }
      ai_generations: {
        Row: {
          cost_usd_micros: number
          created_at: string
          error: string | null
          id: string
          input_ref: string | null
          job_id: string
          latency_ms: number | null
          model: string | null
          output_path: string | null
          provider: string
          status: string
        }
        Insert: {
          cost_usd_micros?: number
          created_at?: string
          error?: string | null
          id?: string
          input_ref?: string | null
          job_id: string
          latency_ms?: number | null
          model?: string | null
          output_path?: string | null
          provider: string
          status: string
        }
        Update: {
          cost_usd_micros?: number
          created_at?: string
          error?: string | null
          id?: string
          input_ref?: string | null
          job_id?: string
          latency_ms?: number | null
          model?: string | null
          output_path?: string | null
          provider?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_generations_job_id_fkey"
            columns: ["job_id"]
            isOneToOne: false
            referencedRelation: "ai_jobs"
            referencedColumns: ["id"]
          },
        ]
      }
      ai_jobs: {
        Row: {
          attempts: number
          completed_at: string | null
          created_at: string
          error: string | null
          free_regenerations: number
          id: string
          input_image_ids: string[]
          kind: Database["public"]["Enums"]["ai_job_kind"]
          locked_at: string | null
          max_attempts: number
          options: Json
          output_path: string | null
          progress: number
          property_id: string | null
          provider: string | null
          render_mode: string | null
          started_at: string | null
          status: Database["public"]["Enums"]["ai_job_status"]
          updated_at: string
          user_id: string
        }
        Insert: {
          attempts?: number
          completed_at?: string | null
          created_at?: string
          error?: string | null
          free_regenerations?: number
          id?: string
          input_image_ids?: string[]
          kind: Database["public"]["Enums"]["ai_job_kind"]
          locked_at?: string | null
          max_attempts?: number
          options?: Json
          output_path?: string | null
          progress?: number
          property_id?: string | null
          provider?: string | null
          render_mode?: string | null
          started_at?: string | null
          status?: Database["public"]["Enums"]["ai_job_status"]
          updated_at?: string
          user_id: string
        }
        Update: {
          attempts?: number
          completed_at?: string | null
          created_at?: string
          error?: string | null
          free_regenerations?: number
          id?: string
          input_image_ids?: string[]
          kind?: Database["public"]["Enums"]["ai_job_kind"]
          locked_at?: string | null
          max_attempts?: number
          options?: Json
          output_path?: string | null
          progress?: number
          property_id?: string | null
          provider?: string | null
          render_mode?: string | null
          started_at?: string | null
          status?: Database["public"]["Enums"]["ai_job_status"]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ai_jobs_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
      ai_provider_config: {
        Row: {
          daily_budget_usd_micros: number | null
          feature: Database["public"]["Enums"]["ai_job_kind"]
          is_enabled: boolean
          model: string | null
          priority: number
          provider: string
          updated_at: string
        }
        Insert: {
          daily_budget_usd_micros?: number | null
          feature: Database["public"]["Enums"]["ai_job_kind"]
          is_enabled?: boolean
          model?: string | null
          priority?: number
          provider: string
          updated_at?: string
        }
        Update: {
          daily_budget_usd_micros?: number | null
          feature?: Database["public"]["Enums"]["ai_job_kind"]
          is_enabled?: boolean
          model?: string | null
          priority?: number
          provider?: string
          updated_at?: string
        }
        Relationships: []
      }
      ai_usage: {
        Row: {
          cost_usd_micros: number
          day: string
          feature: Database["public"]["Enums"]["ai_job_kind"]
          units: number
          user_id: string
        }
        Insert: {
          cost_usd_micros?: number
          day?: string
          feature: Database["public"]["Enums"]["ai_job_kind"]
          units?: number
          user_id: string
        }
        Update: {
          cost_usd_micros?: number
          day?: string
          feature?: Database["public"]["Enums"]["ai_job_kind"]
          units?: number
          user_id?: string
        }
        Relationships: []
      }
      application_settings: {
        Row: {
          is_public: boolean
          key: string
          updated_at: string
          updated_by: string | null
          value: Json
        }
        Insert: {
          is_public?: boolean
          key: string
          updated_at?: string
          updated_by?: string | null
          value: Json
        }
        Update: {
          is_public?: boolean
          key?: string
          updated_at?: string
          updated_by?: string | null
          value?: Json
        }
        Relationships: []
      }
      banners: {
        Row: {
          created_at: string
          ends_at: string | null
          id: string
          image_path: string
          is_active: boolean
          link: string | null
          locale: string | null
          sort_order: number
          starts_at: string
        }
        Insert: {
          created_at?: string
          ends_at?: string | null
          id?: string
          image_path: string
          is_active?: boolean
          link?: string | null
          locale?: string | null
          sort_order?: number
          starts_at?: string
        }
        Update: {
          created_at?: string
          ends_at?: string | null
          id?: string
          image_path?: string
          is_active?: boolean
          link?: string | null
          locale?: string | null
          sort_order?: number
          starts_at?: string
        }
        Relationships: []
      }
      companies: {
        Row: {
          created_at: string
          deleted_at: string | null
          description_ar: string | null
          description_ckb: string | null
          description_en: string | null
          district_id: number | null
          governorate_id: number | null
          id: string
          is_developer: boolean
          logo_path: string | null
          name: string
          office_address: string | null
          office_location: unknown
          owner_id: string
          phones: string[]
          slug: string
          socials: Json
          updated_at: string
          verified: boolean
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          description_ar?: string | null
          description_ckb?: string | null
          description_en?: string | null
          district_id?: number | null
          governorate_id?: number | null
          id?: string
          is_developer?: boolean
          logo_path?: string | null
          name: string
          office_address?: string | null
          office_location?: unknown
          owner_id: string
          phones?: string[]
          slug: string
          socials?: Json
          updated_at?: string
          verified?: boolean
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          description_ar?: string | null
          description_ckb?: string | null
          description_en?: string | null
          district_id?: number | null
          governorate_id?: number | null
          id?: string
          is_developer?: boolean
          logo_path?: string | null
          name?: string
          office_address?: string | null
          office_location?: unknown
          owner_id?: string
          phones?: string[]
          slug?: string
          socials?: Json
          updated_at?: string
          verified?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "companies_district_id_fkey"
            columns: ["district_id"]
            isOneToOne: false
            referencedRelation: "districts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "companies_governorate_id_fkey"
            columns: ["governorate_id"]
            isOneToOne: false
            referencedRelation: "governorates"
            referencedColumns: ["id"]
          },
        ]
      }
      company_members: {
        Row: {
          company_id: string
          created_at: string
          invited_by: string | null
          role: Database["public"]["Enums"]["company_role"]
          status: string
          user_id: string
        }
        Insert: {
          company_id: string
          created_at?: string
          invited_by?: string | null
          role?: Database["public"]["Enums"]["company_role"]
          status?: string
          user_id: string
        }
        Update: {
          company_id?: string
          created_at?: string
          invited_by?: string | null
          role?: Database["public"]["Enums"]["company_role"]
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "company_members_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
        ]
      }
      conversation_members: {
        Row: {
          conversation_id: string
          last_read_at: string | null
          muted: boolean
          unread_count: number
          user_id: string
        }
        Insert: {
          conversation_id: string
          last_read_at?: string | null
          muted?: boolean
          unread_count?: number
          user_id: string
        }
        Update: {
          conversation_id?: string
          last_read_at?: string | null
          muted?: boolean
          unread_count?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "conversation_members_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      conversations: {
        Row: {
          created_at: string
          created_by: string
          id: string
          last_message_at: string | null
          last_message_preview: string | null
          pair_key: string
          property_id: string | null
        }
        Insert: {
          created_at?: string
          created_by: string
          id?: string
          last_message_at?: string | null
          last_message_preview?: string | null
          pair_key: string
          property_id?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string
          id?: string
          last_message_at?: string | null
          last_message_preview?: string | null
          pair_key?: string
          property_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "conversations_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
      districts: {
        Row: {
          center: unknown
          governorate_id: number
          id: number
          is_active: boolean
          name_ar: string
          name_ckb: string
          name_en: string
        }
        Insert: {
          center?: unknown
          governorate_id: number
          id?: never
          is_active?: boolean
          name_ar: string
          name_ckb: string
          name_en: string
        }
        Update: {
          center?: unknown
          governorate_id?: number
          id?: never
          is_active?: boolean
          name_ar?: string
          name_ckb?: string
          name_en?: string
        }
        Relationships: [
          {
            foreignKeyName: "districts_governorate_id_fkey"
            columns: ["governorate_id"]
            isOneToOne: false
            referencedRelation: "governorates"
            referencedColumns: ["id"]
          },
        ]
      }
      governorates: {
        Row: {
          center: unknown
          code: string
          id: number
          is_active: boolean
          name_ar: string
          name_ckb: string
          name_en: string
          sort_order: number
        }
        Insert: {
          center?: unknown
          code: string
          id?: never
          is_active?: boolean
          name_ar: string
          name_ckb: string
          name_en: string
          sort_order?: number
        }
        Update: {
          center?: unknown
          code?: string
          id?: never
          is_active?: boolean
          name_ar?: string
          name_ckb?: string
          name_en?: string
          sort_order?: number
        }
        Relationships: []
      }
      jobs: {
        Row: {
          attempts: number
          created_at: string
          id: number
          last_error: string | null
          locked_at: string | null
          payload: Json
          run_at: string
          status: string
          type: string
        }
        Insert: {
          attempts?: number
          created_at?: string
          id?: never
          last_error?: string | null
          locked_at?: string | null
          payload?: Json
          run_at?: string
          status?: string
          type: string
        }
        Update: {
          attempts?: number
          created_at?: string
          id?: never
          last_error?: string | null
          locked_at?: string | null
          payload?: Json
          run_at?: string
          status?: string
          type?: string
        }
        Relationships: []
      }
      leads: {
        Row: {
          assigned_to: string | null
          company_id: string | null
          created_at: string
          customer_id: string
          id: string
          note: string | null
          owner_id: string
          property_id: string
          source: Database["public"]["Enums"]["lead_source"]
          status: Database["public"]["Enums"]["lead_status"]
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          company_id?: string | null
          created_at?: string
          customer_id: string
          id?: string
          note?: string | null
          owner_id: string
          property_id: string
          source: Database["public"]["Enums"]["lead_source"]
          status?: Database["public"]["Enums"]["lead_status"]
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          company_id?: string | null
          created_at?: string
          customer_id?: string
          id?: string
          note?: string | null
          owner_id?: string
          property_id?: string
          source?: Database["public"]["Enums"]["lead_source"]
          status?: Database["public"]["Enums"]["lead_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "leads_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leads_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
      message_reports: {
        Row: {
          created_at: string
          details: string | null
          id: string
          message_id: string
          reason: string
          reporter_id: string
          status: string
        }
        Insert: {
          created_at?: string
          details?: string | null
          id?: string
          message_id: string
          reason: string
          reporter_id: string
          status?: string
        }
        Update: {
          created_at?: string
          details?: string | null
          id?: string
          message_id?: string
          reason?: string
          reporter_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "message_reports_message_id_fkey"
            columns: ["message_id"]
            isOneToOne: false
            referencedRelation: "messages"
            referencedColumns: ["id"]
          },
        ]
      }
      messages: {
        Row: {
          attachment_path: string | null
          body: string | null
          conversation_id: string
          created_at: string
          deleted_at: string | null
          id: string
          sender_id: string
        }
        Insert: {
          attachment_path?: string | null
          body?: string | null
          conversation_id: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          sender_id: string
        }
        Update: {
          attachment_path?: string | null
          body?: string | null
          conversation_id?: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_conversation_id_fkey"
            columns: ["conversation_id"]
            isOneToOne: false
            referencedRelation: "conversations"
            referencedColumns: ["id"]
          },
        ]
      }
      neighborhoods: {
        Row: {
          center: unknown
          created_at: string
          created_by: string | null
          district_id: number
          id: string
          name_ar: string | null
          name_ckb: string | null
          name_en: string | null
          name_normalized: string | null
          name_original: string
          original_locale: string
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["public"]["Enums"]["place_status"]
          updated_at: string
        }
        Insert: {
          center?: unknown
          created_at?: string
          created_by?: string | null
          district_id: number
          id?: string
          name_ar?: string | null
          name_ckb?: string | null
          name_en?: string | null
          name_normalized?: string | null
          name_original: string
          original_locale?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["place_status"]
          updated_at?: string
        }
        Update: {
          center?: unknown
          created_at?: string
          created_by?: string | null
          district_id?: number
          id?: string
          name_ar?: string | null
          name_ckb?: string | null
          name_en?: string | null
          name_normalized?: string | null
          name_original?: string
          original_locale?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: Database["public"]["Enums"]["place_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "neighborhoods_district_id_fkey"
            columns: ["district_id"]
            isOneToOne: false
            referencedRelation: "districts"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          body_key: string | null
          created_at: string
          data: Json
          id: string
          params: Json
          pushed_at: string | null
          read_at: string | null
          title_key: string
          type: string
          user_id: string
        }
        Insert: {
          body_key?: string | null
          created_at?: string
          data?: Json
          id?: string
          params?: Json
          pushed_at?: string | null
          read_at?: string | null
          title_key: string
          type: string
          user_id: string
        }
        Update: {
          body_key?: string | null
          created_at?: string
          data?: Json
          id?: string
          params?: Json
          pushed_at?: string | null
          read_at?: string | null
          title_key?: string
          type?: string
          user_id?: string
        }
        Relationships: []
      }
      payment_audit_logs: {
        Row: {
          action: string
          actor: string
          created_at: string
          details: Json
          from_status: Database["public"]["Enums"]["payment_status"] | null
          id: number
          order_id: string | null
          to_status: Database["public"]["Enums"]["payment_status"] | null
        }
        Insert: {
          action: string
          actor: string
          created_at?: string
          details?: Json
          from_status?: Database["public"]["Enums"]["payment_status"] | null
          id?: never
          order_id?: string | null
          to_status?: Database["public"]["Enums"]["payment_status"] | null
        }
        Update: {
          action?: string
          actor?: string
          created_at?: string
          details?: Json
          from_status?: Database["public"]["Enums"]["payment_status"] | null
          id?: never
          order_id?: string | null
          to_status?: Database["public"]["Enums"]["payment_status"] | null
        }
        Relationships: [
          {
            foreignKeyName: "payment_audit_logs_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "payment_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_orders: {
        Row: {
          ai_job_id: string | null
          amount: number
          created_at: string
          currency: string
          expires_at: string
          failure_reason: string | null
          id: string
          idempotency_key: string
          internal_reference: string
          paid_at: string | null
          property_id: string | null
          provider: Database["public"]["Enums"]["payment_provider"]
          refund_status: Database["public"]["Enums"]["refund_status"]
          service_type: Database["public"]["Enums"]["service_type"]
          status: Database["public"]["Enums"]["payment_status"]
          updated_at: string
          user_id: string
        }
        Insert: {
          ai_job_id?: string | null
          amount: number
          created_at?: string
          currency: string
          expires_at?: string
          failure_reason?: string | null
          id?: string
          idempotency_key: string
          internal_reference: string
          paid_at?: string | null
          property_id?: string | null
          provider: Database["public"]["Enums"]["payment_provider"]
          refund_status?: Database["public"]["Enums"]["refund_status"]
          service_type: Database["public"]["Enums"]["service_type"]
          status?: Database["public"]["Enums"]["payment_status"]
          updated_at?: string
          user_id: string
        }
        Update: {
          ai_job_id?: string | null
          amount?: number
          created_at?: string
          currency?: string
          expires_at?: string
          failure_reason?: string | null
          id?: string
          idempotency_key?: string
          internal_reference?: string
          paid_at?: string | null
          property_id?: string | null
          provider?: Database["public"]["Enums"]["payment_provider"]
          refund_status?: Database["public"]["Enums"]["refund_status"]
          service_type?: Database["public"]["Enums"]["service_type"]
          status?: Database["public"]["Enums"]["payment_status"]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_orders_ai_job_fk"
            columns: ["ai_job_id"]
            isOneToOne: false
            referencedRelation: "ai_jobs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_orders_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_provider_events: {
        Row: {
          dedup_key: string
          id: number
          payload: Json
          processed_at: string | null
          processing_error: string | null
          provider: Database["public"]["Enums"]["payment_provider"]
          received_at: string
          signature_valid: boolean | null
        }
        Insert: {
          dedup_key: string
          id?: never
          payload: Json
          processed_at?: string | null
          processing_error?: string | null
          provider: Database["public"]["Enums"]["payment_provider"]
          received_at?: string
          signature_valid?: boolean | null
        }
        Update: {
          dedup_key?: string
          id?: never
          payload?: Json
          processed_at?: string | null
          processing_error?: string | null
          provider?: Database["public"]["Enums"]["payment_provider"]
          received_at?: string
          signature_valid?: boolean | null
        }
        Relationships: []
      }
      payment_refunds: {
        Row: {
          amount: number
          approved_by: string | null
          created_at: string
          id: string
          manual_reference: string | null
          order_id: string
          provider_refund_id: string | null
          reason: string
          requested_by: string | null
          status: Database["public"]["Enums"]["refund_status"]
          transaction_id: string | null
          updated_at: string
        }
        Insert: {
          amount: number
          approved_by?: string | null
          created_at?: string
          id?: string
          manual_reference?: string | null
          order_id: string
          provider_refund_id?: string | null
          reason: string
          requested_by?: string | null
          status?: Database["public"]["Enums"]["refund_status"]
          transaction_id?: string | null
          updated_at?: string
        }
        Update: {
          amount?: number
          approved_by?: string | null
          created_at?: string
          id?: string
          manual_reference?: string | null
          order_id?: string
          provider_refund_id?: string | null
          reason?: string
          requested_by?: string | null
          status?: Database["public"]["Enums"]["refund_status"]
          transaction_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_refunds_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "payment_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_refunds_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "payment_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_settings: {
        Row: {
          applies_to_transaction_types: Database["public"]["Enums"]["transaction_type"][]
          currency: string
          is_enabled: boolean
          price_amount: number
          service_type: Database["public"]["Enums"]["service_type"]
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          applies_to_transaction_types?: Database["public"]["Enums"]["transaction_type"][]
          currency?: string
          is_enabled?: boolean
          price_amount: number
          service_type: Database["public"]["Enums"]["service_type"]
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          applies_to_transaction_types?: Database["public"]["Enums"]["transaction_type"][]
          currency?: string
          is_enabled?: boolean
          price_amount?: number
          service_type?: Database["public"]["Enums"]["service_type"]
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      payment_transactions: {
        Row: {
          amount: number
          created_at: string
          currency: string
          id: string
          order_id: string
          provider: Database["public"]["Enums"]["payment_provider"]
          provider_payload: Json
          provider_payment_id: string
          status: Database["public"]["Enums"]["payment_status"]
          updated_at: string
          valid_until: string | null
        }
        Insert: {
          amount: number
          created_at?: string
          currency: string
          id?: string
          order_id: string
          provider: Database["public"]["Enums"]["payment_provider"]
          provider_payload?: Json
          provider_payment_id: string
          status?: Database["public"]["Enums"]["payment_status"]
          updated_at?: string
          valid_until?: string | null
        }
        Update: {
          amount?: number
          created_at?: string
          currency?: string
          id?: string
          order_id?: string
          provider?: Database["public"]["Enums"]["payment_provider"]
          provider_payload?: Json
          provider_payment_id?: string
          status?: Database["public"]["Enums"]["payment_status"]
          updated_at?: string
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payment_transactions_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "payment_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          account_type: Database["public"]["Enums"]["account_type"]
          avatar_path: string | null
          created_at: string
          deleted_at: string | null
          district_id: number | null
          email: string | null
          full_name: string | null
          governorate_id: number | null
          id: string
          identity_verified: boolean
          is_suspended: boolean
          onboarded_at: string | null
          phone: string | null
          phone_verified: boolean
          preferred_locale: string
          rating_avg: number
          rating_count: number
          show_phone: boolean
          updated_at: string
        }
        Insert: {
          account_type?: Database["public"]["Enums"]["account_type"]
          avatar_path?: string | null
          created_at?: string
          deleted_at?: string | null
          district_id?: number | null
          email?: string | null
          full_name?: string | null
          governorate_id?: number | null
          id: string
          identity_verified?: boolean
          is_suspended?: boolean
          onboarded_at?: string | null
          phone?: string | null
          phone_verified?: boolean
          preferred_locale?: string
          rating_avg?: number
          rating_count?: number
          show_phone?: boolean
          updated_at?: string
        }
        Update: {
          account_type?: Database["public"]["Enums"]["account_type"]
          avatar_path?: string | null
          created_at?: string
          deleted_at?: string | null
          district_id?: number | null
          email?: string | null
          full_name?: string | null
          governorate_id?: number | null
          id?: string
          identity_verified?: boolean
          is_suspended?: boolean
          onboarded_at?: string | null
          phone?: string | null
          phone_verified?: boolean
          preferred_locale?: string
          rating_avg?: number
          rating_count?: number
          show_phone?: boolean
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "profiles_district_id_fkey"
            columns: ["district_id"]
            isOneToOne: false
            referencedRelation: "districts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "profiles_governorate_id_fkey"
            columns: ["governorate_id"]
            isOneToOne: false
            referencedRelation: "governorates"
            referencedColumns: ["id"]
          },
        ]
      }
      properties: {
        Row: {
          address_text: string | null
          area_sqm: number | null
          assigned_agent_id: string | null
          attributes: Json
          availability_date: string | null
          bathrooms: number | null
          bedrooms: number | null
          building_condition: string | null
          category_id: number
          company_id: string | null
          contact_phone: string | null
          cooling: string | null
          created_at: string
          deleted_at: string | null
          description: string | null
          district_id: number
          electricity: string | null
          expires_at: string | null
          favorites_count: number
          featured_until: string | null
          floor_number: number | null
          floors: number | null
          furnishing: string | null
          governorate_id: number
          has_internet: boolean | null
          has_parking: boolean | null
          heating: string | null
          id: string
          is_featured: boolean
          listing_state: Database["public"]["Enums"]["listing_state"]
          location: unknown
          neighborhood_id: string | null
          owner_id: string
          ownership_doc_status: string | null
          price_amount: number
          price_currency: string
          price_negotiable: boolean
          property_age_years: number | null
          publication_status: Database["public"]["Enums"]["publication_status"]
          published_at: string | null
          rejection_reason: string | null
          search_tsv: unknown
          show_phone: boolean
          title: string
          transaction_type: Database["public"]["Enums"]["transaction_type"]
          updated_at: string
          views_count: number
          water: string | null
        }
        Insert: {
          address_text?: string | null
          area_sqm?: number | null
          assigned_agent_id?: string | null
          attributes?: Json
          availability_date?: string | null
          bathrooms?: number | null
          bedrooms?: number | null
          building_condition?: string | null
          category_id: number
          company_id?: string | null
          contact_phone?: string | null
          cooling?: string | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          district_id: number
          electricity?: string | null
          expires_at?: string | null
          favorites_count?: number
          featured_until?: string | null
          floor_number?: number | null
          floors?: number | null
          furnishing?: string | null
          governorate_id: number
          has_internet?: boolean | null
          has_parking?: boolean | null
          heating?: string | null
          id?: string
          is_featured?: boolean
          listing_state?: Database["public"]["Enums"]["listing_state"]
          location?: unknown
          neighborhood_id?: string | null
          owner_id: string
          ownership_doc_status?: string | null
          price_amount: number
          price_currency?: string
          price_negotiable?: boolean
          property_age_years?: number | null
          publication_status?: Database["public"]["Enums"]["publication_status"]
          published_at?: string | null
          rejection_reason?: string | null
          search_tsv?: unknown
          show_phone?: boolean
          title: string
          transaction_type: Database["public"]["Enums"]["transaction_type"]
          updated_at?: string
          views_count?: number
          water?: string | null
        }
        Update: {
          address_text?: string | null
          area_sqm?: number | null
          assigned_agent_id?: string | null
          attributes?: Json
          availability_date?: string | null
          bathrooms?: number | null
          bedrooms?: number | null
          building_condition?: string | null
          category_id?: number
          company_id?: string | null
          contact_phone?: string | null
          cooling?: string | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          district_id?: number
          electricity?: string | null
          expires_at?: string | null
          favorites_count?: number
          featured_until?: string | null
          floor_number?: number | null
          floors?: number | null
          furnishing?: string | null
          governorate_id?: number
          has_internet?: boolean | null
          has_parking?: boolean | null
          heating?: string | null
          id?: string
          is_featured?: boolean
          listing_state?: Database["public"]["Enums"]["listing_state"]
          location?: unknown
          neighborhood_id?: string | null
          owner_id?: string
          ownership_doc_status?: string | null
          price_amount?: number
          price_currency?: string
          price_negotiable?: boolean
          property_age_years?: number | null
          publication_status?: Database["public"]["Enums"]["publication_status"]
          published_at?: string | null
          rejection_reason?: string | null
          search_tsv?: unknown
          show_phone?: boolean
          title?: string
          transaction_type?: Database["public"]["Enums"]["transaction_type"]
          updated_at?: string
          views_count?: number
          water?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "properties_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "property_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "properties_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "properties_district_id_fkey"
            columns: ["district_id"]
            isOneToOne: false
            referencedRelation: "districts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "properties_governorate_id_fkey"
            columns: ["governorate_id"]
            isOneToOne: false
            referencedRelation: "governorates"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "properties_neighborhood_id_fkey"
            columns: ["neighborhood_id"]
            isOneToOne: false
            referencedRelation: "neighborhoods"
            referencedColumns: ["id"]
          },
        ]
      }
      property_categories: {
        Row: {
          allowed_transaction_types: Database["public"]["Enums"]["transaction_type"][]
          fields: string[]
          group: Database["public"]["Enums"]["category_group"]
          icon: string | null
          id: number
          is_active: boolean
          name_ar: string
          name_ckb: string
          name_en: string
          slug: string
          sort_order: number
        }
        Insert: {
          allowed_transaction_types?: Database["public"]["Enums"]["transaction_type"][]
          fields?: string[]
          group: Database["public"]["Enums"]["category_group"]
          icon?: string | null
          id?: never
          is_active?: boolean
          name_ar: string
          name_ckb: string
          name_en: string
          slug: string
          sort_order?: number
        }
        Update: {
          allowed_transaction_types?: Database["public"]["Enums"]["transaction_type"][]
          fields?: string[]
          group?: Database["public"]["Enums"]["category_group"]
          icon?: string | null
          id?: never
          is_active?: boolean
          name_ar?: string
          name_ckb?: string
          name_en?: string
          slug?: string
          sort_order?: number
        }
        Relationships: []
      }
      property_comparisons: {
        Row: {
          property_ids: string[]
          updated_at: string
          user_id: string
        }
        Insert: {
          property_ids?: string[]
          updated_at?: string
          user_id: string
        }
        Update: {
          property_ids?: string[]
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      property_favorites: {
        Row: {
          created_at: string
          folder: string | null
          property_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          folder?: string | null
          property_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          folder?: string | null
          property_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "property_favorites_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
      property_features: {
        Row: {
          icon: string | null
          id: number
          is_active: boolean
          name_ar: string
          name_ckb: string
          name_en: string
          slug: string
        }
        Insert: {
          icon?: string | null
          id?: never
          is_active?: boolean
          name_ar: string
          name_ckb: string
          name_en: string
          slug: string
        }
        Update: {
          icon?: string | null
          id?: never
          is_active?: boolean
          name_ar?: string
          name_ckb?: string
          name_en?: string
          slug?: string
        }
        Relationships: []
      }
      property_images: {
        Row: {
          ai_label: string | null
          ai_variant_of: string | null
          bytes: number | null
          created_at: string
          height: number | null
          id: string
          is_cover: boolean
          mime: string | null
          owner_id: string
          phash: number | null
          property_id: string
          sort_order: number
          status: string
          storage_path: string
          thumb_path: string | null
          width: number | null
        }
        Insert: {
          ai_label?: string | null
          ai_variant_of?: string | null
          bytes?: number | null
          created_at?: string
          height?: number | null
          id?: string
          is_cover?: boolean
          mime?: string | null
          owner_id: string
          phash?: number | null
          property_id: string
          sort_order?: number
          status?: string
          storage_path: string
          thumb_path?: string | null
          width?: number | null
        }
        Update: {
          ai_label?: string | null
          ai_variant_of?: string | null
          bytes?: number | null
          created_at?: string
          height?: number | null
          id?: string
          is_cover?: boolean
          mime?: string | null
          owner_id?: string
          phash?: number | null
          property_id?: string
          sort_order?: number
          status?: string
          storage_path?: string
          thumb_path?: string | null
          width?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "property_images_ai_variant_of_fkey"
            columns: ["ai_variant_of"]
            isOneToOne: false
            referencedRelation: "property_images"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "property_images_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
      property_reports: {
        Row: {
          created_at: string
          details: string | null
          handled_by: string | null
          id: string
          property_id: string
          reason: string
          reporter_id: string
          status: string
        }
        Insert: {
          created_at?: string
          details?: string | null
          handled_by?: string | null
          id?: string
          property_id: string
          reason: string
          reporter_id: string
          status?: string
        }
        Update: {
          created_at?: string
          details?: string | null
          handled_by?: string | null
          id?: string
          property_id?: string
          reason?: string
          reporter_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "property_reports_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
      property_status_history: {
        Row: {
          actor_id: string | null
          created_at: string
          from_status: Database["public"]["Enums"]["publication_status"] | null
          id: number
          property_id: string
          reason: string | null
          to_status: Database["public"]["Enums"]["publication_status"]
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          from_status?: Database["public"]["Enums"]["publication_status"] | null
          id?: never
          property_id: string
          reason?: string | null
          to_status: Database["public"]["Enums"]["publication_status"]
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          from_status?: Database["public"]["Enums"]["publication_status"] | null
          id?: never
          property_id?: string
          reason?: string | null
          to_status?: Database["public"]["Enums"]["publication_status"]
        }
        Relationships: [
          {
            foreignKeyName: "property_status_history_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
      property_videos: {
        Row: {
          ai_job_id: string | null
          aspect: string | null
          created_at: string
          duration_s: number | null
          id: string
          owner_id: string
          poster_path: string | null
          property_id: string
          sort_order: number
          source: string
          storage_path: string
        }
        Insert: {
          ai_job_id?: string | null
          aspect?: string | null
          created_at?: string
          duration_s?: number | null
          id?: string
          owner_id: string
          poster_path?: string | null
          property_id: string
          sort_order?: number
          source: string
          storage_path: string
        }
        Update: {
          ai_job_id?: string | null
          aspect?: string | null
          created_at?: string
          duration_s?: number | null
          id?: string
          owner_id?: string
          poster_path?: string | null
          property_id?: string
          sort_order?: number
          source?: string
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "property_videos_ai_job_id_fkey"
            columns: ["ai_job_id"]
            isOneToOne: false
            referencedRelation: "ai_jobs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "property_videos_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
      property_views: {
        Row: {
          property_id: string
          viewed_on: string
          viewer_id: string
        }
        Insert: {
          property_id: string
          viewed_on?: string
          viewer_id: string
        }
        Update: {
          property_id?: string
          viewed_on?: string
          viewer_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "property_views_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
      recently_viewed: {
        Row: {
          property_id: string
          user_id: string
          viewed_at: string
        }
        Insert: {
          property_id: string
          user_id: string
          viewed_at?: string
        }
        Update: {
          property_id?: string
          user_id?: string
          viewed_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "recently_viewed_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
      saved_searches: {
        Row: {
          alert_enabled: boolean
          created_at: string
          filters: Json
          id: string
          last_alerted_at: string | null
          name: string
          user_id: string
        }
        Insert: {
          alert_enabled?: boolean
          created_at?: string
          filters: Json
          id?: string
          last_alerted_at?: string | null
          name: string
          user_id: string
        }
        Update: {
          alert_enabled?: boolean
          created_at?: string
          filters?: Json
          id?: string
          last_alerted_at?: string | null
          name?: string
          user_id?: string
        }
        Relationships: []
      }
      search_alerts: {
        Row: {
          property_id: string
          saved_search_id: string
          sent_at: string
        }
        Insert: {
          property_id: string
          saved_search_id: string
          sent_at?: string
        }
        Update: {
          property_id?: string
          saved_search_id?: string
          sent_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "search_alerts_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "search_alerts_saved_search_id_fkey"
            columns: ["saved_search_id"]
            isOneToOne: false
            referencedRelation: "saved_searches"
            referencedColumns: ["id"]
          },
        ]
      }
      user_blocks: {
        Row: {
          blocked_id: string
          blocker_id: string
          created_at: string
        }
        Insert: {
          blocked_id: string
          blocker_id: string
          created_at?: string
        }
        Update: {
          blocked_id?: string
          blocker_id?: string
          created_at?: string
        }
        Relationships: []
      }
      user_devices: {
        Row: {
          fcm_token: string
          id: string
          last_seen_at: string
          locale: string
          platform: string
          user_id: string
        }
        Insert: {
          fcm_token: string
          id?: string
          last_seen_at?: string
          locale?: string
          platform: string
          user_id: string
        }
        Update: {
          fcm_token?: string
          id?: string
          last_seen_at?: string
          locale?: string
          platform?: string
          user_id?: string
        }
        Relationships: []
      }
      user_roles: {
        Row: {
          granted_at: string
          granted_by: string | null
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          granted_at?: string
          granted_by?: string | null
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          granted_at?: string
          granted_by?: string | null
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
      verification_requests: {
        Row: {
          company_id: string | null
          created_at: string
          decided_at: string | null
          decided_by: string | null
          documents: string[]
          id: string
          kind: Database["public"]["Enums"]["verification_kind"]
          notes: string | null
          property_id: string | null
          state: Database["public"]["Enums"]["verification_state"]
          user_id: string
        }
        Insert: {
          company_id?: string | null
          created_at?: string
          decided_at?: string | null
          decided_by?: string | null
          documents: string[]
          id?: string
          kind: Database["public"]["Enums"]["verification_kind"]
          notes?: string | null
          property_id?: string | null
          state?: Database["public"]["Enums"]["verification_state"]
          user_id: string
        }
        Update: {
          company_id?: string | null
          created_at?: string
          decided_at?: string | null
          decided_by?: string | null
          documents?: string[]
          id?: string
          kind?: Database["public"]["Enums"]["verification_kind"]
          notes?: string | null
          property_id?: string | null
          state?: Database["public"]["Enums"]["verification_state"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "verification_requests_company_id_fkey"
            columns: ["company_id"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "verification_requests_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      ai_job_claim: {
        Args: { p_kind?: Database["public"]["Enums"]["ai_job_kind"] }
        Returns: {
          attempts: number
          completed_at: string | null
          created_at: string
          error: string | null
          free_regenerations: number
          id: string
          input_image_ids: string[]
          kind: Database["public"]["Enums"]["ai_job_kind"]
          locked_at: string | null
          max_attempts: number
          options: Json
          output_path: string | null
          progress: number
          property_id: string | null
          provider: string | null
          render_mode: string | null
          started_at: string | null
          status: Database["public"]["Enums"]["ai_job_status"]
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "ai_jobs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      ai_job_complete: {
        Args: {
          p_duration: number
          p_job: string
          p_output_path: string
          p_provider: string
          p_render_mode: string
        }
        Returns: {
          attempts: number
          completed_at: string | null
          created_at: string
          error: string | null
          free_regenerations: number
          id: string
          input_image_ids: string[]
          kind: Database["public"]["Enums"]["ai_job_kind"]
          locked_at: string | null
          max_attempts: number
          options: Json
          output_path: string | null
          progress: number
          property_id: string | null
          provider: string | null
          render_mode: string | null
          started_at: string | null
          status: Database["public"]["Enums"]["ai_job_status"]
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "ai_jobs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      ai_job_fail: {
        Args: { p_error: string; p_job: string }
        Returns: {
          attempts: number
          completed_at: string | null
          created_at: string
          error: string | null
          free_regenerations: number
          id: string
          input_image_ids: string[]
          kind: Database["public"]["Enums"]["ai_job_kind"]
          locked_at: string | null
          max_attempts: number
          options: Json
          output_path: string | null
          progress: number
          property_id: string | null
          provider: string | null
          render_mode: string | null
          started_at: string | null
          status: Database["public"]["Enums"]["ai_job_status"]
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "ai_jobs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      ai_job_progress: {
        Args: { p_job: string; p_progress: number }
        Returns: undefined
      }
      ai_job_regenerate: {
        Args: { p_job: string; p_user: string }
        Returns: {
          attempts: number
          completed_at: string | null
          created_at: string
          error: string | null
          free_regenerations: number
          id: string
          input_image_ids: string[]
          kind: Database["public"]["Enums"]["ai_job_kind"]
          locked_at: string | null
          max_attempts: number
          options: Json
          output_path: string | null
          progress: number
          property_id: string | null
          provider: string | null
          render_mode: string | null
          started_at: string | null
          status: Database["public"]["Enums"]["ai_job_status"]
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "ai_jobs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      ai_video_create: {
        Args: {
          p_image_ids: string[]
          p_options: Json
          p_property: string
          p_user: string
        }
        Returns: {
          attempts: number
          completed_at: string | null
          created_at: string
          error: string | null
          free_regenerations: number
          id: string
          input_image_ids: string[]
          kind: Database["public"]["Enums"]["ai_job_kind"]
          locked_at: string | null
          max_attempts: number
          options: Json
          output_path: string | null
          progress: number
          property_id: string | null
          provider: string | null
          render_mode: string | null
          started_at: string | null
          status: Database["public"]["Enums"]["ai_job_status"]
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "ai_jobs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      company_role_of: {
        Args: { p_company: string }
        Returns: Database["public"]["Enums"]["company_role"]
      }
      conversation_can_send: { Args: { p_conv: string }; Returns: boolean }
      conversation_is_member: { Args: { p_conv: string }; Returns: boolean }
      conversation_mark_read: { Args: { p_conv: string }; Returns: undefined }
      conversation_open: {
        Args: { p_other: string; p_property?: string }
        Returns: string
      }
      get_public_profiles: {
        Args: { p_ids: string[] }
        Returns: {
          account_type: Database["public"]["Enums"]["account_type"]
          avatar_path: string
          created_at: string
          district_id: number
          full_name: string
          governorate_id: number
          id: string
          identity_verified: boolean
          phone: string
          phone_verified: boolean
          rating_avg: number
          rating_count: number
        }[]
      }
      has_role: {
        Args: { p_role: Database["public"]["Enums"]["app_role"] }
        Returns: boolean
      }
      is_staff: { Args: never; Returns: boolean }
      lead_record: {
        Args: {
          p_property: string
          p_source: Database["public"]["Enums"]["lead_source"]
        }
        Returns: undefined
      }
      normalize_place_name: { Args: { p: string }; Returns: string }
      payment_attach_transaction: {
        Args: {
          p_order: string
          p_payload: Json
          p_provider_payment_id: string
          p_valid_until: string
        }
        Returns: {
          amount: number
          created_at: string
          currency: string
          id: string
          order_id: string
          provider: Database["public"]["Enums"]["payment_provider"]
          provider_payload: Json
          provider_payment_id: string
          status: Database["public"]["Enums"]["payment_status"]
          updated_at: string
          valid_until: string | null
        }
        SetofOptions: {
          from: "*"
          to: "payment_transactions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      payment_create_order: {
        Args: {
          p_ai_job: string
          p_idempotency_key: string
          p_property: string
          p_provider: Database["public"]["Enums"]["payment_provider"]
          p_service: Database["public"]["Enums"]["service_type"]
          p_user: string
        }
        Returns: {
          ai_job_id: string | null
          amount: number
          created_at: string
          currency: string
          expires_at: string
          failure_reason: string | null
          id: string
          idempotency_key: string
          internal_reference: string
          paid_at: string | null
          property_id: string | null
          provider: Database["public"]["Enums"]["payment_provider"]
          refund_status: Database["public"]["Enums"]["refund_status"]
          service_type: Database["public"]["Enums"]["service_type"]
          status: Database["public"]["Enums"]["payment_status"]
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      payment_log: {
        Args: {
          p_action: string
          p_actor: string
          p_details?: Json
          p_from: Database["public"]["Enums"]["payment_status"]
          p_order: string
          p_to: Database["public"]["Enums"]["payment_status"]
        }
        Returns: undefined
      }
      payment_mark_failed: {
        Args: {
          p_order: string
          p_reason: string
          p_status: Database["public"]["Enums"]["payment_status"]
        }
        Returns: {
          ai_job_id: string | null
          amount: number
          created_at: string
          currency: string
          expires_at: string
          failure_reason: string | null
          id: string
          idempotency_key: string
          internal_reference: string
          paid_at: string | null
          property_id: string | null
          provider: Database["public"]["Enums"]["payment_provider"]
          refund_status: Database["public"]["Enums"]["refund_status"]
          service_type: Database["public"]["Enums"]["service_type"]
          status: Database["public"]["Enums"]["payment_status"]
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      payment_mark_paid: {
        Args: {
          p_amount: number
          p_currency: string
          p_payload: Json
          p_provider: Database["public"]["Enums"]["payment_provider"]
          p_provider_payment_id: string
        }
        Returns: {
          ai_job_id: string | null
          amount: number
          created_at: string
          currency: string
          expires_at: string
          failure_reason: string | null
          id: string
          idempotency_key: string
          internal_reference: string
          paid_at: string | null
          property_id: string | null
          provider: Database["public"]["Enums"]["payment_provider"]
          refund_status: Database["public"]["Enums"]["refund_status"]
          service_type: Database["public"]["Enums"]["service_type"]
          status: Database["public"]["Enums"]["payment_status"]
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      payment_new_reference: { Args: never; Returns: string }
      payment_request_refund: {
        Args: { p_actor: string; p_order: string; p_reason: string }
        Returns: {
          amount: number
          approved_by: string | null
          created_at: string
          id: string
          manual_reference: string | null
          order_id: string
          provider_refund_id: string | null
          reason: string
          requested_by: string | null
          status: Database["public"]["Enums"]["refund_status"]
          transaction_id: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_refunds"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      property_fee_required: { Args: { p_property: string }; Returns: boolean }
      property_is_mine_editable: { Args: { p_id: string }; Returns: boolean }
      property_is_public: { Args: { p_id: string }; Returns: boolean }
      property_submit: {
        Args: { p_property: string; p_user: string }
        Returns: Database["public"]["Enums"]["publication_status"]
      }
      record_property_view: { Args: { p_property: string }; Returns: undefined }
      search_properties: {
        Args: { p_filters?: Json; p_limit?: number; p_offset?: number }
        Returns: {
          area_sqm: number
          bathrooms: number
          bedrooms: number
          category_id: number
          company_verified: boolean
          cover_path: string
          distance_m: number
          district_id: number
          favorites_count: number
          governorate_id: number
          id: string
          is_featured: boolean
          lat: number
          lng: number
          neighborhood_id: string
          owner_identity_verified: boolean
          owner_phone_verified: boolean
          price_amount: number
          price_currency: string
          price_negotiable: boolean
          published_at: string
          title: string
          transaction_type: Database["public"]["Enums"]["transaction_type"]
          views_count: number
        }[]
      }
      suggest_neighborhood: {
        Args: { p_district_id: number; p_locale?: string; p_name: string }
        Returns: {
          center: unknown
          created_at: string
          created_by: string | null
          district_id: number
          id: string
          name_ar: string | null
          name_ckb: string | null
          name_en: string | null
          name_normalized: string | null
          name_original: string
          original_locale: string
          reviewed_at: string | null
          reviewed_by: string | null
          status: Database["public"]["Enums"]["place_status"]
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "neighborhoods"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      users_blocked: { Args: { p_a: string; p_b: string }; Returns: boolean }
    }
    Enums: {
      account_type: "individual" | "owner" | "agent" | "company" | "developer"
      ai_job_kind: "video" | "image_enhance" | "virtual_staging" | "text"
      ai_job_status:
        | "draft"
        | "pending_payment"
        | "payment_processing"
        | "payment_failed"
        | "payment_paid"
        | "queued"
        | "processing"
        | "completed"
        | "failed"
        | "cancelled"
        | "refund_pending"
        | "refunded"
      app_role: "user" | "moderator" | "admin" | "finance_admin" | "super_admin"
      category_group: "residential" | "commercial" | "land"
      company_role: "owner" | "manager" | "agent" | "viewer"
      lead_source: "call" | "whatsapp" | "message"
      lead_status:
        | "new"
        | "contacted"
        | "qualified"
        | "closed_won"
        | "closed_lost"
      listing_state: "active" | "paused" | "sold" | "rented" | "archived"
      payment_provider: "FIB" | "QI_CARD"
      payment_status:
        | "created"
        | "pending"
        | "processing"
        | "paid"
        | "failed"
        | "cancelled"
        | "expired"
        | "refunded"
        | "partially_refunded"
      place_status: "approved" | "pending" | "rejected"
      publication_status:
        | "draft"
        | "pending_payment"
        | "payment_processing"
        | "payment_failed"
        | "payment_paid"
        | "pending_approval"
        | "approved"
        | "rejected"
        | "published"
        | "suspended"
        | "expired"
      refund_status:
        | "none"
        | "requested"
        | "processing"
        | "completed"
        | "failed"
      service_type: "PROPERTY_PUBLISHING" | "AI_VIDEO_GENERATION"
      transaction_type: "sale" | "rent" | "short_term_rent" | "investment"
      verification_kind: "identity" | "agency" | "company" | "property_document"
      verification_state: "pending" | "approved" | "rejected"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
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
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
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
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
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
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      account_type: ["individual", "owner", "agent", "company", "developer"],
      ai_job_kind: ["video", "image_enhance", "virtual_staging", "text"],
      ai_job_status: [
        "draft",
        "pending_payment",
        "payment_processing",
        "payment_failed",
        "payment_paid",
        "queued",
        "processing",
        "completed",
        "failed",
        "cancelled",
        "refund_pending",
        "refunded",
      ],
      app_role: ["user", "moderator", "admin", "finance_admin", "super_admin"],
      category_group: ["residential", "commercial", "land"],
      company_role: ["owner", "manager", "agent", "viewer"],
      lead_source: ["call", "whatsapp", "message"],
      lead_status: [
        "new",
        "contacted",
        "qualified",
        "closed_won",
        "closed_lost",
      ],
      listing_state: ["active", "paused", "sold", "rented", "archived"],
      payment_provider: ["FIB", "QI_CARD"],
      payment_status: [
        "created",
        "pending",
        "processing",
        "paid",
        "failed",
        "cancelled",
        "expired",
        "refunded",
        "partially_refunded",
      ],
      place_status: ["approved", "pending", "rejected"],
      publication_status: [
        "draft",
        "pending_payment",
        "payment_processing",
        "payment_failed",
        "payment_paid",
        "pending_approval",
        "approved",
        "rejected",
        "published",
        "suspended",
        "expired",
      ],
      refund_status: ["none", "requested", "processing", "completed", "failed"],
      service_type: ["PROPERTY_PUBLISHING", "AI_VIDEO_GENERATION"],
      transaction_type: ["sale", "rent", "short_term_rent", "investment"],
      verification_kind: ["identity", "agency", "company", "property_document"],
      verification_state: ["pending", "approved", "rejected"],
    },
  },
} as const
