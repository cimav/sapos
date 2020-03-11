class AddEmailAndPhoneToGraduates < ActiveRecord::Migration
  def change
    add_column :graduates, :email, :string
    add_column :graduates, :phone, :string
  end
end
