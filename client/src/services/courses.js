import { supabase } from '../lib/supabase'

export async function fetchCourses() {
  const { data, error } = await supabase.from('courses').select('*').order('title')
  if (error) throw error
  return data || []
}

export async function createCourse(title, level, extra = {}) {
  const { age_group = null, sublevel = null, teacher_id = null } = extra
  const { data, error } = await supabase
    .from('courses')
    .insert([{ title, level, age_group, sublevel, teacher_id }])
    .select()
  if (error) throw error
  return data
}

export async function fetchLessons(courseId) {
  const { data, error } = await supabase
    .from('lessons')
    .select('*')
    .eq('course_id', courseId)
    .order('position')
  if (error) throw error
  return data || []
}

export async function createLesson(courseId, title, position = 1) {
  const { data, error } = await supabase
    .from('lessons')
    .insert([{ course_id: courseId, title, position }])
    .select()
  if (error) throw error
  return data
}

export async function fetchTeacherCourses(teacherId) {
  const { data, error } = await supabase
    .from('courses')
    .select('*')
    .eq('teacher_id', teacherId)
    .order('title')
  if (error) throw error
  return data || []
}

// Alias usado por el dashboard docente
export const fetchCoursesForTeacher = fetchTeacherCourses

export async function assignTeacherToCourse(courseId, teacherId) {
  const { error } = await supabase
    .from('courses')
    .update({ teacher_id: teacherId })
    .eq('id', courseId)
  if (error) throw error
}

export async function fetchCoursesWithTeacher() {
  const { data, error } = await supabase
    .from('courses')
    .select('id, title, level, teacher_id, profiles:teacher_id ( display_name, email )')
    .order('title')
  if (error) throw error
  return data || []
}

/**
 * Todos los cursos, agrupados por age_group → level, para el panel de admin.
 */
export async function fetchAllCoursesGrouped() {
  const { data, error } = await supabase.from('courses').select('*').order('title')
  if (error) throw error

  const grouped = {}
  ;(data || []).forEach((course) => {
    const ageKey = course.age_group || 'sin_asignar'
    const levelKey = course.level || 'Sin nivel'
    if (!grouped[ageKey]) grouped[ageKey] = {}
    if (!grouped[ageKey][levelKey]) grouped[ageKey][levelKey] = []
    grouped[ageKey][levelKey].push(course)
  })
  return grouped
}

export async function fetchTeacherStudentCount(teacherId) {
  const courses = await fetchTeacherCourses(teacherId)
  if (!courses.length) return 0
  const { data, error } = await supabase
    .from('enrollments')
    .select('student_id', { count: 'exact', head: false })
    .in(
      'course_id',
      courses.map((c) => c.id),
    )
  if (error) throw error
  return new Set((data || []).map((e) => e.student_id)).size
}
