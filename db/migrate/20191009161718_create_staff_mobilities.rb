class CreateStaffMobilities < ActiveRecord::Migration
  def change
    create_table :staff_mobilities do |t|
      t.references :student
      t.date :start_date
      t.date :end_date
      t.string :place
      t.references :institution
      t.text :title
      t.text :activities
      
      t.timestamps
    end
    
    add_index("staff_mobilities", "student_id")
    add_index("staff_mobilities", "institution_id")
  end

end
