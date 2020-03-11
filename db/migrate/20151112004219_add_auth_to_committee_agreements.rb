class AddAuthToCommitteeAgreements < ActiveRecord::Migration
  def change
    add_column :committee_agreements, :auth, :string
  end
end
