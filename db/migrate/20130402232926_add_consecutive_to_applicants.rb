class AddConsecutiveToApplicants < ActiveRecord::Migration
  def up
    add_column :applicants,:consecutive, :integer
  end

  def down
    remove_column :applicants, :consecutive
  end
end
