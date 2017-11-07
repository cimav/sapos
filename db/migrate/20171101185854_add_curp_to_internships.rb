class AddCurpToInternships < ActiveRecord::Migration
  def change
    add_column :internships, :curp, :string
  end
end
