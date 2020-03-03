class ChangeCertificatesTypeColumnName < ActiveRecord::Migration
  def up
    rename_column :certificates, :type, :type_id
  end

  def down
  end
end
