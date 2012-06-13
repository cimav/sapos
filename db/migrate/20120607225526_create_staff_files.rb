class CreateStaffFiles < ActiveRecord::Migration
  def self.up
    create_table :staff_files do |t|
      t.references :staff
      t.string  "description"
      t.string  "file"

      t.timestamps
    end
    add_index("staff_files", "staff_id")
  end

  def self.down
    drop_table :staff_files
  end
end
