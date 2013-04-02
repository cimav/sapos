class CreateApplicants < ActiveRecord::Migration
  def up
    create_table :applicants do |t|
      t.references :program
      t.string "folio"
      t.string "first_name"
      t.string "primary_last_name"
      t.string "second_last_name"
      t.integer "previous_institution"
      t.string "previous_degree_type"
      t.string  "average"
      t.date "date_of_birth"
      t.string "phone"
      t.string "cell_phone"
      t.string "email"
      t.string "address"
      t.integer "civil_status"
    
      t.timestamps  
    end
    
  end

  def down
    drop_table :applicants
  end
end
