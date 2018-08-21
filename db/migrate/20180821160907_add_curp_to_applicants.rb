class AddCurpToApplicants < ActiveRecord::Migration
  def change
    add_column :applicants, :curp, :string
  end
end
