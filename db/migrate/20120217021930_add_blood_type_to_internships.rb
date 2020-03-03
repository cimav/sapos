class AddBloodTypeToInternships < ActiveRecord::Migration
  def self.up
    add_column :internships, :blood_type, :string
  end

  def self.down
    remove_column :internships, :blood_type
  end
end
