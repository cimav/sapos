class AddCountryIdToApplicants < ActiveRecord::Migration
  def change
    add_column :applicants, :country_id, :integer
    add_column :applicants, :state_id, :integer
  end
end
