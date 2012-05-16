class CreateDocumentationFiles < ActiveRecord::Migration
  def self.up
    create_table :documentation_files do |t|
      t.references :program
      t.string "description"
      t.string "file"

      t.timestamps
    end
    add_index("documentation_files","program_id")
  end

  def self.down
    drop_table :documentation_files
  end
end
