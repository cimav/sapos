class CreateTokens < ActiveRecord::Migration
  def up
    create_table :tokens do |t|
      t.integer  "attachable_id"
      t.integer  "attachable_type"
      t.string   "token"
      t.datetime "expires"
      t.integer  "status"
      t.timestamps
    end
  end

  def down
  end
end
