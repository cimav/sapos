class CreateApplicantFiles < ActiveRecord::Migration
  def up
    create_table :applicant_files do |t|
      t.references :applicant
      t.integer "file_type" 
      t.string "description"
      t.string "file"
    end
    add_index("applicant_files", "applicant_id")
  end

  def down
    drop_table :applicant_files
  end
end
