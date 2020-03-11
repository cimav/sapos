class CreateStudentTeacherEvaluations < ActiveRecord::Migration
  def change
    create_table :student_teacher_evaluations do |t|
      t.references :student
      t.references :staff
      t.references :term_course
    end
  end
end
