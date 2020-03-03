class AddPasswordToInternships < ActiveRecord::Migration
  def change
    add_column :internships,:password,:string
  end
end
