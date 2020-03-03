class AddUhNumberToStaffs < ActiveRecord::Migration
  def change
    add_column :staffs, :uh_number, :integer
  end
end
