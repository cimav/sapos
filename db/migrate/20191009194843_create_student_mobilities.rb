class CreateStudentMobilities < ActiveRecord::Migration
  def change
    create_table :student_mobilities do |t|
      t.references :student
      t.date :start_date
      t.date :end_date
      t.string :place
      t.references :institution
      t.references :staff
      t.text :title
      t.text :activities
      
      t.timestamps
    end
    
    add_index("student_mobilities", "student_id")
    add_index("student_mobilities", "institution_id")
    add_index("student_mobilities", "staff_id")
  end
end
