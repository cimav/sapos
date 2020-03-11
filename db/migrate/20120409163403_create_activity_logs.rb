class CreateActivityLogs < ActiveRecord::Migration
  def self.up
    create_table :activity_logs do |t|
      t.references :user
      t.text "activity"
      t.timestamps
    end
    
  end

  def self.down
    drop_table :activity_logs
  end
end
