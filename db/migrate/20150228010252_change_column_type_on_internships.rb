class ChangeColumnTypeOnInternships < ActiveRecord::Migration
  def up
    change_column :internships, :status, :integer
  end

  def down
    change_column :internships, :status, :string, :limit=>20
  end
end
