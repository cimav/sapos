class AddAreaIdToStaffs < ActiveRecord::Migration
  def up
    add_column :staffs, :area_id, :integer
  end
  
  def down
    remove_column :staffs, :area_id
  end
end
