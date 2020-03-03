class AddCampusToApplicants < ActiveRecord::Migration
  def self.up
    add_column :applicants, :campus_id, :integer
  end

  def self.down
    remove_column :applicants, :campus_id
  end
end
