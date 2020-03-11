class CreateGraduates < ActiveRecord::Migration
  def up
    create_table :graduates do |t|
      t.references :student
      t.string "workplace", :limit => 100
      t.integer "income"
      t.integer "gyre"
      t.text "prizes"
      t.string  "sni", :limit => 20
      t.integer  "sni_status"
      t.text  "subsequent_studies"
      t.date "period_from"
      t.date "period_to"
      
      t.timestamps
    end
    
    add_index("graduates", "student_id")
  end

  def down
    drop_table :graduates
  end
end
