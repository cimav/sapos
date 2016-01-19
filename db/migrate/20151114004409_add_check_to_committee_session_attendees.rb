class AddCheckToCommitteeSessionAttendees < ActiveRecord::Migration
  def change
    add_column :committee_session_attendees, :checked, :boolean, default: false
  end
end
