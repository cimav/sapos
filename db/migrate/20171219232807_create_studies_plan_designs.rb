class CreateStudiesPlanDesigns < ActiveRecord::Migration
  def change
    create_table :studies_plan_designs do |t|
      t.references :studies_plan
      t.references :staff
      t.integer :modification_type_id
      t.date :design_date
      
      t.timestamps
    end
  end
end
