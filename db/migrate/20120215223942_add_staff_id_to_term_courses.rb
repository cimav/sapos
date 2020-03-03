class AddStaffIdToTermCourses < ActiveRecord::Migration
  def self.up
    add_column :term_courses, :staff_id, :integer
    add_index("term_courses", "staff_id")
  end

  def self.down
    remove_index("term_courses", "staff_id")
    remove_column :term_courses, :staff_id
  end
end
