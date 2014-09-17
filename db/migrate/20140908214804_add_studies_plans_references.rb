class AddStudiesPlansReferences < ActiveRecord::Migration
  def up
    add_column :students, :studies_plan_id, :integer
    add_column :courses, :studies_plan_id, :integer
  end

  def down
    remove_column :students, :studies_plan_id
    remove_column :courses, :studies_plan_id
  end
end
