import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL =
  import.meta.env.VITE_SUPABASE_URL || 'https://nuqvqeynhssipmcmebxb.supabase.co'
const SUPABASE_ANON_KEY =
  import.meta.env.VITE_SUPABASE_ANON_KEY || 'sb_publishable_WjBgPoBpB1ONRrQh_JSucA_X_cCiDZY'

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// Buckets (mismos nombres que en backend.js / library.js)
export const MATERIALS_BUCKET = 'materials'
export const LIBRARY_BUCKET = 'library-files'
