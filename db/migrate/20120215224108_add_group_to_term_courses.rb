class AddGroupToTermCourses < ActiveRecord::Migration
  def self.up
    add_column :term_courses, :group, :string
  end

  def self.down
    remove_column :term_courses, :group
  end
end
