class CreateCommitteAgreements < ActiveRecord::Migration
  def up
    create_table :committee_agreements do |t|
      t.references :committee_agreement_type
      t.references :committee_session
      t.timestamps
    end
  end

  def down
    drop_table :committee_agreements
  end
end
