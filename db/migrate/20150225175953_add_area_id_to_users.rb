class AddAreaIdToUsers < ActiveRecord::Migration
  def up
    add_column :users, :areas, :string, :limit=> 150
  end

  def down
    remove_column :users, :areas
  end
end
