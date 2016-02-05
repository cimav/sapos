class AddEndSessionToCommitteeSession < ActiveRecord::Migration
  def change
    add_column :committee_sessions, :end_session, :datetime
  end
end
