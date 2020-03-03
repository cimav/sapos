class CreateTeacherEvaluations < ActiveRecord::Migration
  def change
    create_table :teacher_evaluations do |t|
      t.references :staff
      t.references :term_course
      t.integer :question1
      t.integer :question2
      t.integer :question3
      t.integer :question4
      t.integer :question5
      t.integer :question6
      t.integer :question7
      t.integer :question8
      t.integer :question9
      t.integer :question10
      t.integer :question11
      t.integer :question12

      t.timestamps
    end
    add_index :teacher_evaluations, :staff_id
    add_index :teacher_evaluations, :term_course_id
  end
end
