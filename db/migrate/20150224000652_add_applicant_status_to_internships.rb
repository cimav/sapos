class AddApplicantStatusToInternships < ActiveRecord::Migration
  def up
    add_column :internships, :applicant_status, :integer
  end

  def down
    remove_column :internships, :applicant_status
  end
end
