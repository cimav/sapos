class AddTypeToPrograms < ActiveRecord::Migration
  def self.up
    add_column :programs, :program_type, :integer
  end

  def self.down
    remove_column :programs, :program_type
  end 
end
