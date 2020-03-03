class CreateStudiesPlans < ActiveRecord::Migration
  def up
     create_table :studies_plans do |t|
      t.references :program
      t.string     :code,  :limit => 20,  :null => false
      t.string     :name,  :limit => 100
      t.text       :notes
      t.string     :status,        :limit => 20, :default => 0
      t.timestamps
    end

    add_index("studies_plans", "program_id")
  end

  def down
    drop_table :studies_plans
  end
end
