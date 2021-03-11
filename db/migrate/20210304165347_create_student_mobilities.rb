class CreateStudentMobilities < ActiveRecord::Migration
  def up
    create_table :student_mobilities do |t|
      t.references :student
      t.text       "activities"
      t.string     "institution"
      t.datetime   "start_date"
      t.datetime   "end_date"
      t.string     "national", :limit => 1, :default => 1
      t.string     "status", :limit => 1, :default => 1
      t.timestamps
    end
    add_index("student_mobilities", "student_id")
  end

  def down
    drop_table :student_mobilities 
  end
end
