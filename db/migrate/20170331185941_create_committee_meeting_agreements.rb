class CreateCommitteeMeetingAgreements < ActiveRecord::Migration
  def change
    create_table :committee_meeting_agreements do |t|
      t.references :committee_meeting
      t.integer :status
      t.integer :type
      t.string :description

      t.timestamps
    end
    add_index :committee_meeting_agreements, :committee_meeting_id
  end
end
