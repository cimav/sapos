class AddTypeToExternalCourses < ActiveRecord::Migration
  def change
    add_column :external_courses, :course_type, :integer
  end
end
