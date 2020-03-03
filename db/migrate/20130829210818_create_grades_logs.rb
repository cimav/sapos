class CreateGradesLogs < ActiveRecord::Migration
  def up
    create_table :grades_logs do |t|
      t.references :staff
      t.references :term_course_student
      t.timestamps
    end
  end

  def down
    drop_table :grades_logs
  end
end
