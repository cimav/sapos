class CreateAreas < ActiveRecord::Migration
  def up
    create_table :areas do |t|
      t.string  "name",         :limit => 100, :null => false
      t.integer "area_type",         :null  => false
      t.string  "leader",       :limit => 100
      t.string  "position"     
      t.text "notes"
      t.timestamps
    end
  end

  def down
    drop_table :areas
  end
end
