class AddDateToCommitteSessions < ActiveRecord::Migration
  def change
    add_column :committee_sessions, :date, :datetime
  end
end
