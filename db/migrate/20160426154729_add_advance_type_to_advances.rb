class AddAdvanceTypeToAdvances < ActiveRecord::Migration
  def change
    add_column :advances, :advance_type, :integer 
  end
end
