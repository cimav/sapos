class AddCareerOfficeTotalHoursSheduleToInterships < ActiveRecord::Migration
  def self.up
    add_column :internships, :career, :string
    add_column :internships, :office, :string
    add_column :internships, :total_hours, :integer
    add_column :internships, :schedule, :string
  end

  def self.down
    remove_column :internships, :career
    remove_column :internships, :office
    remove_column :internships, :total_hours
    remove_column :internships, :schedule
  end 
end
