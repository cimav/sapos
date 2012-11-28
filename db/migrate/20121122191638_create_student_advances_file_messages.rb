class CreateStudentAdvancesFileMessages < ActiveRecord::Migration
  def change
    create_table :student_advances_file_messages do |t|
      t.references :student_advances_file
      t.integer    "attachable_id"
      t.string     "attachable_type"
      t.text       "message"
      t.timestamps
    end
  end
  
  def self.down
    drop_table :student_advances_file_messages
  end
end
