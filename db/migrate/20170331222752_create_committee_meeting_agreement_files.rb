class CreateCommitteeMeetingAgreementFiles < ActiveRecord::Migration
  def change
    create_table :committee_files do |t|
      t.references :committee_meeting_agreement
      t.string :file
      t.string :name

      t.timestamps
    end
    add_index :committee_files, :committee_meeting_agreement_id
  end
end
