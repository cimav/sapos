class AddAreaIdToStudents < ActiveRecord::Migration
  def change
	add_column :students, :area_id, :integer
  end
end
