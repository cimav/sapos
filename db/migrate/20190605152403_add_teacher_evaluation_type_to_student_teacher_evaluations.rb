class AddTeacherEvaluationTypeToStudentTeacherEvaluations < ActiveRecord::Migration
  def change
    add_column :student_teacher_evaluations, :teacher_evaluation_type, :integer
  end
end
