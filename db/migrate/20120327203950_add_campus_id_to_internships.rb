class AddCampusIdToInternships < ActiveRecord::Migration
  def self.up
    add_column :internships, :campus_id, :integer
  end

  def self.down
    remove_column :internships, :campus_id
  end
end
