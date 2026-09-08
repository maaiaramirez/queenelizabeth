import { supabase } from '../lib/supabase'

/**
 * Registra un nuevo usuario y crea su perfil con el rol indicado.
 * role: 'student' | 'teacher' | 'admin'
 */
export async function signUpUser(email, password, displayName, role = 'student') {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { display_name: displayName, role } },
  })
  if (error) throw error

  // El trigger on_auth_user_created de Supabase debería crear el perfil solo,
  // pero por las dudas lo garantizamos también acá (idempotente, no duplica).
  if (data.session?.access_token) {
    try {
      await fetch('/api/auth/ensure-profile', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${data.session.access_token}`,
        },
        body: JSON.stringify({ displayName, role }),
      })
    } catch (e) {
      console.error('No se pudo asegurar el perfil vía API:', e)
    }
  }

  return data
}

export async function signInUser(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
  return data
}

export async function signOutUser() {
  const { error } = await supabase.auth.signOut()
  if (error) throw error
}

export async function getCurrentUser() {
  const {
    data: { user },
  } = await supabase.auth.getUser()
  return user
}

export async function getCurrentProfile() {
  const user = await getCurrentUser()
  if (!user) return null
  let { data, error } = await supabase.from('profiles').select('*').eq('id', user.id).single()
  if (error) {
    // Perfil faltante (cuenta vieja/rota): lo creamos ahora mismo, server-side.
    const {
      data: { session },
    } = await supabase.auth.getSession()
    if (session?.access_token) {
      try {
        await fetch('/api/auth/ensure-profile', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${session.access_token}` },
          body: JSON.stringify({ displayName: user.user_metadata?.display_name, role: user.user_metadata?.role }),
        })
        ;({ data, error } = await supabase.from('profiles').select('*').eq('id', user.id).single())
      } catch (e) {
        console.error('No se pudo autoreparar el perfil:', e)
      }
    }
  }
  if (error) return null
  return data
}

export function onAuthStateChange(callback) {
  return supabase.auth.onAuthStateChange((event, session) => callback(event, session))
}

export async function checkTeacherAccess() {
  const profile = await getCurrentProfile()
  return !!profile && (profile.role === 'teacher' || profile.role === 'admin')
}

export function traducirError(msg) {
  if (!msg) return 'Ocurrió un error inesperado.'
  if (msg.includes('Invalid login credentials')) return 'Email o contraseña incorrectos.'
  if (msg.includes('Email not confirmed')) return 'Confirmá tu email antes de ingresar.'
  if (msg.includes('User already registered')) return 'Ese email ya tiene una cuenta registrada.'
  if (msg.includes('Password should be')) return 'La contraseña debe tener al menos 6 caracteres.'
  return msg
}

export function rolLabel(role) {
  return { admin: 'Admin', teacher: 'Docente', student: 'Alumno' }[role] || role
}
