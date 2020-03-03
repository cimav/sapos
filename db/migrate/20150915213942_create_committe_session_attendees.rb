class CreateCommitteSessionAttendees < ActiveRecord::Migration
  def up
    create_table :committee_session_attendees do |t|
      t.references :committee_session
      t.references :staff
      t.references :department
      t.timestamps
    end
  end

  def down
    drop_table :committee_session_attendees
  end
end
