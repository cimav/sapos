class AddColumnsToInternships < ActiveRecord::Migration
  def up
    add_column :internships, :area_id, :integer
    add_column :internships, :country_id, :integer
    add_column :internships, :state_id, :integer
  end

  def down
    remove_column :internships, :area_id
    remove_column :internships, :country_id
    remove_column :internships, :state_id
  end
end
