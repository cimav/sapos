class CreateCommitteeAgreementFiles < ActiveRecord::Migration
  def change
    create_table :committee_agreement_files do |t|
      t.references :committee_agreement
      t.string :description
      t.string :file
      t.timestamps
    end
    add_index("committee_agreement_files", "committee_agreement_id")
  end
end
