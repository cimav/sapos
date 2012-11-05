class CreateStudentAdvancesFiles < ActiveRecord::Migration
  def self.up
    create_table :student_advances_files do |t|
      t.references :term_student
      t.integer "student_advance_type"
      t.string "description"
      t.string "file"

      t.timestamps
    end
  end

  def self.down
    drop_table :student_files
  end
end
