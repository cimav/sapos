class AddProgramTypeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :program_type, :integer
  end

  def self.down
    remove_column :users, :program_type
  end
end
