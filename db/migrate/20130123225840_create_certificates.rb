class CreateCertificates < ActiveRecord::Migration
  def up
    create_table :certificates do |t|
      t.integer  "consecutive"
      t.integer  "year"       
      t.integer  "attachable_id"
      t.string   "attachable_type"
      t.integer  "type"
      t.timestamps
    end 
  end

  def down
    drop_table :certificates
  end
end
