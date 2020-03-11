class AddLastName2ToStudents < ActiveRecord::Migration
  def change
    add_column :students, :last_name2, :string
  end
end
