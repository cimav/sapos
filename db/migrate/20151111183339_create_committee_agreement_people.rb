class CreateCommitteeAgreementPeople < ActiveRecord::Migration
  def change
    create_table :committee_agreement_people do |t|
      t.references :committee_agreement
      t.integer :attachable_id
      t.integer :attachable_type
      t.timestamps
    end
    add_index("committee_agreement_people", "committee_agreement_id")
  end
end
