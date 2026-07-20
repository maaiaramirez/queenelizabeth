import { supabase, MATERIALS_BUCKET } from '../lib/supabase'
import { getCurrentUser } from './auth'

export async function fetchAllMaterials() {
  const { data, error } = await supabase
    .from('materials')
    .select(
      `
      id, title, type, description, file_path, external_url, created_at,
      lessons ( id, title, courses ( id, title, level ) )
    `,
    )
    .order('created_at', { ascending: false })
  if (error) throw error
  return data || []
}

export function getMaterialPublicUrl(filePath) {
  if (!filePath) return null
  const { data } = supabase.storage.from(MATERIALS_BUCKET).getPublicUrl(filePath)
  return data?.publicUrl || null
}

export async function logMaterialEvent(materialId, action = 'view') {
  const user = await getCurrentUser()
  const { error } = await supabase.from('material_events').insert([
    {
      material_id: materialId,
      action,
      student_id: user?.id || null,
      student_name: user?.email ? user.email.split('@')[0] : 'Usuario',
      student_email: user?.email || 'anonimo@academy.com',
    },
  ])
  if (error) console.error('Error al registrar evento:', error)
}

export async function uploadMaterial({ file, lessonId, title, type, description, externalUrl }) {
  let filePath = null
  if (file && type !== 'link') {
    const fileExt = file.name.split('.').pop()
    const cleanName = `${Date.now()}_${Math.random().toString(36).substring(2, 7)}.${fileExt}`
    const { data: storageData, error: storageError } = await supabase.storage
      .from(MATERIALS_BUCKET)
      .upload(cleanName, file)
    if (storageError) throw storageError
    filePath = storageData.path
  }
  const { data, error } = await supabase
    .from('materials')
    .insert([
      {
        lesson_id: lessonId,
        title,
        type,
        description,
        file_path: filePath,
        external_url: type === 'link' ? externalUrl : null,
      },
    ])
    .select()
  if (error) throw error
  return data
}

export async function deleteMaterial(materialId, filePath = null) {
  const { error: dbError } = await supabase.from('materials').delete().eq('id', materialId)
  if (dbError) throw dbError
  if (filePath) {
    const { error: storageError } = await supabase.storage.from(MATERIALS_BUCKET).remove([filePath])
    if (storageError) console.error('Aviso Storage:', storageError.message)
  }
}

export const TYPE_ICONS = { pdf: '📄', video: '🎬', audio: '🎧', doc: '📝', link: '🔗' }
