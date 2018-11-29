class CreateSystemConfigs < ActiveRecord::Migration
  def change
    create_table :system_configs do |t|

      t.timestamps
    end
  end
end
