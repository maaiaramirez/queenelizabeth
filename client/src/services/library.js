import { supabase, LIBRARY_BUCKET } from '../lib/supabase'

// Tipos de archivo que SÍ se suben a Supabase Storage.
// Video siempre es external_url (YouTube/Vimeo/etc), nunca se sube acá.
export const UPLOADABLE_TYPES = ['pdf', 'audio', 'image', 'document']
export const ICONS = { pdf: '📄', video: '🎬', audio: '🎵', image: '🖼️', document: '📝', link: '🔗' }

// --------- CARPETAS ---------

export async function getFolders(parentFolderId = null) {
  let query = supabase.from('library_folders').select('*').order('name', { ascending: true })
  if (parentFolderId === null) {
    query = query.is('parent_folder_id', null)
  } else {
    query = query.eq('parent_folder_id', parentFolderId)
  }
  const { data, error } = await query
  if (error) throw error
  return data
}

export async function createFolder(name, parentFolderId = null) {
  const { data: userData } = await supabase.auth.getUser()
  const { data, error } = await supabase
    .from('library_folders')
    .insert({ name, parent_folder_id: parentFolderId, created_by: userData.user.id })
    .select()
    .single()
  if (error) throw error
  return data
}

export async function renameFolder(folderId, newName) {
  const { error } = await supabase.from('library_folders').update({ name: newName }).eq('id', folderId)
  if (error) throw error
}

export async function deleteFolder(folderId) {
  const { error } = await supabase.from('library_folders').delete().eq('id', folderId)
  if (error) throw error
}

// --------- ITEMS ---------

export async function getItems({ folderId = null, lessonId = null } = {}) {
  let query = supabase.from('library_items').select('*').order('name')
  if (folderId !== undefined && folderId !== null) {
    query = query.eq('folder_id', folderId)
  } else if (folderId === null) {
    query = query.is('folder_id', null)
  }
  if (lessonId) query = query.eq('lesson_id', lessonId)
  const { data, error } = await query
  if (error) throw error
  return data
}

export async function uploadFileItem({ file, type, folderId, lessonId }) {
  if (!UPLOADABLE_TYPES.includes(type)) {
    throw new Error(`El tipo "${type}" no se sube a Storage, usá createLinkItem() / video por URL`)
  }
  const { data: userData } = await supabase.auth.getUser()
  const path = `${userData.user.id}/${Date.now()}_${file.name}`

  const { error: uploadError } = await supabase.storage
    .from(LIBRARY_BUCKET)
    .upload(path, file, { cacheControl: '3600', upsert: false })
  if (uploadError) throw uploadError

  const { data, error } = await supabase
    .from('library_items')
    .insert({
      name: file.name,
      type,
      folder_id: folderId,
      lesson_id: lessonId || null,
      storage_path: path,
      file_size_bytes: file.size,
      uploaded_by: userData.user.id,
    })
    .select()
    .single()

  if (error) {
    await supabase.storage.from(LIBRARY_BUCKET).remove([path])
    throw error
  }
  return data
}

export async function createLinkItem({ name, type, url, folderId, lessonId }) {
  if (type !== 'video' && type !== 'link') {
    throw new Error('createLinkItem es solo para type=video o type=link')
  }
  const { data: userData } = await supabase.auth.getUser()
  const { data, error } = await supabase
    .from('library_items')
    .insert({
      name,
      type,
      folder_id: folderId,
      lesson_id: lessonId || null,
      external_url: url,
      uploaded_by: userData.user.id,
    })
    .select()
    .single()
  if (error) throw error
  return data
}

export async function deleteItem(item) {
  if (item.storage_path) {
    const { error: storageError } = await supabase.storage.from(LIBRARY_BUCKET).remove([item.storage_path])
    if (storageError) throw storageError
  }
  const { error } = await supabase.from('library_items').delete().eq('id', item.id)
  if (error) throw error
}

export async function getSignedUrl(storagePath) {
  const { data, error } = await supabase.storage.from(LIBRARY_BUCKET).createSignedUrl(storagePath, 3600)
  if (error) throw error
  return data.signedUrl
}

export async function openItem(item) {
  const url = item.external_url || (await getSignedUrl(item.storage_path))
  window.open(url, '_blank')
}
