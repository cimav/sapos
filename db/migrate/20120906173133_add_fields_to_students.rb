class AddFieldsToStudents < ActiveRecord::Migration
  def self.up
    add_column :students, :email_cimav, :string
    add_column :students, :domain_password, :string
  end

  def self.down
    remove_column :students, :email_cimav
    remove_column :students, :domain_password
  end
end
