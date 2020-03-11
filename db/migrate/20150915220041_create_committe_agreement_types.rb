class CreateCommitteAgreementTypes < ActiveRecord::Migration
  def up
    create_table :committee_agreement_types do |t|
      t.string  "description"
      t.integer "authorization" 
      t.timestamps
    end
  end

  def down
    drop_table :committee_agreement_types
  end
end
