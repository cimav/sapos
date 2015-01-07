class AddGradesToAdvances < ActiveRecord::Migration
  def up
    add_column :advances, :grade1, :integer
    add_column :advances, :grade2, :integer
    add_column :advances, :grade3, :integer
    add_column :advances, :grade4, :integer
    add_column :advances, :grade5, :integer
    
    add_column :advances, :grade1_status, :integer
    add_column :advances, :grade2_status, :integer
    add_column :advances, :grade3_status, :integer
    add_column :advances, :grade4_status, :integer
    add_column :advances, :grade5_status, :integer
  end

  def down
    remove_column :advances, :grade1
    remove_column :advances, :grade2
    remove_column :advances, :grade3
    remove_column :advances, :grade4
    remove_column :advances, :grade5
    
    remove_column :advances, :grade1_status
    remove_column :advances, :grade2_status
    remove_column :advances, :grade3_status
    remove_column :advances, :grade4_status
    remove_column :advances, :grade5_status
  end
end
