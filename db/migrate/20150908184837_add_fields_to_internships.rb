class AddFieldsToInternships < ActiveRecord::Migration
  def change
    add_column :internships, :phone, :string, :limit=>20
    add_column :internships, :health_insurance, :string, :limit=>150
    add_column :internships, :health_insurance_number, :string, :limit=>50
    add_column :internships, :accident_contact, :string
  end
end
