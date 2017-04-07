class ChangeTypeColumnName < ActiveRecord::Migration
  def up
    rename_column :committee_meetings, :type, :meeting_type
    rename_column :committee_meeting_agreements, :type, :agreement_type
    rename_column :committee_files, :type, :file_type
  end

  def down
  end
end
