class AddAuxToCommitteeAgreementPeople < ActiveRecord::Migration
  def change
    add_column :committee_agreement_people,:aux,:integer
  end
end
