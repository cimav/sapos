class AddNotesToTeacherEvaluations < ActiveRecord::Migration
  def change
    add_column :teacher_evaluations, :notes, :text
  end
end
