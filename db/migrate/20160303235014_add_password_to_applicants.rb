class AddPasswordToApplicants < ActiveRecord::Migration
  def change
    add_column :applicants,:password,:string
  end
end
