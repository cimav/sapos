class AddDeleteFieldsToStudents < ActiveRecord::Migration
  def self.up
    add_column :students, :deleted, :integer, :default=>0
    add_column :students, :deleted_at, :datetime
  end

  def self.down
    remove_column :students, :deleted
    remove_column :students, :deleted_at
  end
end
