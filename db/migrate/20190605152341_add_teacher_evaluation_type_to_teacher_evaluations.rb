class AddTeacherEvaluationTypeToTeacherEvaluations < ActiveRecord::Migration
  def change
    add_column :teacher_evaluations, :teacher_evaluation_type, :integer
  end
end
