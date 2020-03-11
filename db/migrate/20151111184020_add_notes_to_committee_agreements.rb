class AddNotesToCommitteeAgreements < ActiveRecord::Migration
  def change
    add_column :committee_agreements, :notes, :text
  end
end
