import { supabase } from '../lib/supabase'

export async function enrollStudent(studentId, courseId) {
  const { error } = await supabase.from('enrollments').insert([{ student_id: studentId, course_id: courseId }])
  if (error) throw error
}

export async function fetchCourseStudents(courseId) {
  const { data, error } = await supabase
    .from('enrollments')
    .select('student_id, profiles:student_id ( id, display_name, email )')
    .eq('course_id', courseId)
  if (error) throw error
  return (data || []).map((e) => e.profiles).filter(Boolean)
}

export async function unenrollStudent(studentId, courseId) {
  const { error } = await supabase
    .from('enrollments')
    .delete()
    .eq('student_id', studentId)
    .eq('course_id', courseId)
  if (error) throw error
}
