class AddStudiesPlanAreaIdToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :studies_plan_area_id, :integer
  end
end
