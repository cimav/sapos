class AddColumnsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :program_id, :integer
    add_column :users, :campus_id, :integer
  end

  def self.down
    remove_column :users, :program_id
    remove_column :users, :campus_id
  end
end
