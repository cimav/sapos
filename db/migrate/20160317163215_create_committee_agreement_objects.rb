class CreateCommitteeAgreementObjects < ActiveRecord::Migration
  def change
    create_table :committee_agreement_objects do |t|
      t.references :committee_agreement
      t.integer :attachable_id
      t.string :attachable_type
      t.text :aux
      t.timestamps
    end
    add_index("committee_agreement_objects", "committee_agreement_id")
  end
end
