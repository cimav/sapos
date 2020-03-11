class AddStaffIdToApplicants < ActiveRecord::Migration
  def up
    add_column :applicants, :staff_id, :integer
  end

  def down
    remove_column :applicants, :staff_id
  end
end
