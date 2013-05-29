class AddGradeToInternships < ActiveRecord::Migration
  def self.up
    add_column :internships, :grade, :integer
  end

  def self.down
    remove_column :internships, :grade
  end
end
