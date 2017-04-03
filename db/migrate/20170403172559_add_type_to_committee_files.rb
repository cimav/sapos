class AddTypeToCommitteeFiles < ActiveRecord::Migration
  def change
    add_column :committee_files, :type, :integer
  end
end
