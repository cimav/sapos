class CreateStudiesPlanAreas < ActiveRecord::Migration
  def change
    create_table :studies_plan_areas do |t|
      t.references :studies_plan
      t.string "name"
      t.timestamps
    end
  end
end
