class AddExternalDirectorToStudents < ActiveRecord::Migration
  def change
    add_column :students, :external_supervisor,:integer
  end
end
