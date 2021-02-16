class CreateMobilities < ActiveRecord::Migration
  def up
    create_table :mobilities do |t|
      t.references :staff
      t.text       "activities"
      t.string     "institution"
      t.datetime   "start_date"
      t.datetime   "end_date"
      t.string     "national", :limit => 1, :default => 1
      t.string     "status", :limit => 1, :default => 1
      t.timestamps
    end
    add_index("mobilities", "staff_id")
  end

  def down
    drop_table :mobilities
  end
end
