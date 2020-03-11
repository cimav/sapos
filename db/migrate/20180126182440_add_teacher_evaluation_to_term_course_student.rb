class AddTeacherEvaluationToTermCourseStudent < ActiveRecord::Migration
  def change
    add_column :term_course_students, :teacher_evaluation, :boolean
  end
end
