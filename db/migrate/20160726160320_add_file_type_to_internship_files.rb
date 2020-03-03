class AddFileTypeToInternshipFiles < ActiveRecord::Migration
  def change
    add_column :internship_files, :file_type, :integer
  end
end
