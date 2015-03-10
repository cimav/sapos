class AddFileTypeToStaffFiles < ActiveRecord::Migration
  def up
    add_column :student_files, :file_type, :integer
  end
  
  def down
    remove_column :student_files, :file_type
  end
end
