class ChangeCommitteeAgreementPeopleAttachableType < ActiveRecord::Migration
  def up
    change_column :committee_agreement_people, :attachable_type, :string
  end

  def down
    change_column :committee_agreement_people, :attachable_type, :integer
  end
end
