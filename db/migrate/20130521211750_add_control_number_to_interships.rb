class AddControlNumberToInterships < ActiveRecord::Migration
  def self.up
    add_column :internships, :control_number, :string
  end
 
  def self.down
    remove_column :internships, :control_number
  end
end
