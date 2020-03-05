class AddChosenCampusToInternships < ActiveRecord::Migration
  def change
    add_column :internships, :chosen_campus, :string
  end
end
