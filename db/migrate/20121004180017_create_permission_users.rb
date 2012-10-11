class CreatePermissionUsers < ActiveRecord::Migration
  def self.up
    create_table :permission_users do |t|
      t.references :user
      t.references :program
      t.timestamps
    end

  end

  def self.down
    drop_table :permission_users
  end
end
