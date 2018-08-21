class AddCampusToClassrooms < ActiveRecord::Migration
  def change
    add_column :classrooms, :campus_id, :integer
  end
end
