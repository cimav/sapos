class CreateCommitteeMeetingAgreementResponses < ActiveRecord::Migration
  def change
    create_table :committee_responses do |t|
      t.references :committee_meeting_agreement
      t.references :committee_member
      t.string :note
      t.integer :answer

      t.timestamps
    end
    add_index :committee_responses, :committee_meeting_agreement_id
    add_index :committee_responses, :committee_member_id
  end
end
