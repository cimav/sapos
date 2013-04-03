class AddStatusToApplicants < ActiveRecord::Migration
  def up
    add_column :applicants, :status, :integer
  end

  def down
    remove_column :applicants, :status
  end
end
