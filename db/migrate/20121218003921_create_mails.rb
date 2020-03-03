class CreateMails < ActiveRecord::Migration
  def up
    create_table :emails do |t|
      t.string  "from"
      t.string  "to"
      t.string  "subject"
      t.text    "content" 
      t.integer "status", :default=>0
      t.timestamps
    end
  end

  def down
    drop_table :emails
  end
end
