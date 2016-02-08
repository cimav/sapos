class CreateCommitteeAgreementNotes < ActiveRecord::Migration
  def change
    create_table :committee_agreement_notes do |t|
      t.references :committee_agreement
      t.text "notes"
      t.timestamps 
    end
  end
end
