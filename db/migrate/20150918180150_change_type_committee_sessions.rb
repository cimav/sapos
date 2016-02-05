class ChangeTypeCommitteeSessions < ActiveRecord::Migration
  def change
    rename_column :committee_sessions,:type,:session_type
  end
end
