class AddStatusToClassrooms < ActiveRecord::Migration
  def up
    add_column :classrooms, :status, :integer
  end

  def down
    remove_column :classrooms, :status
  end
end
