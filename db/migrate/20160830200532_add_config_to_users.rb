class AddConfigToUsers < ActiveRecord::Migration
  def change
    add_column :users, :config, :text
  end
end
