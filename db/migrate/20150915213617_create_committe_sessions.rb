class CreateCommitteSessions < ActiveRecord::Migration
  def up
    create_table :committee_sessions do |t|
      t.integer "type"
      t.integer "status"
      t.timestamps
    end
  end

  def down
    drop_table :committee_sessions
  end
end
