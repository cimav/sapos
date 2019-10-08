class EnrollmentFiles < ActiveRecord::Migration
  def up
    create_table :enrollment_files do |t|
      t.integer :enrollment_type_id
      t.references :student
      t.references :term
      t.string "description"
      t.string "file"

      t.timestamps
    end

    add_index("enrollment_files", "student_id")
    add_index("enrollment_files", "term_id")
  end

  def down
    drop_table :enrollment_files
  end
end
