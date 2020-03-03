class CreateCommitteeMeetings < ActiveRecord::Migration
  def change
    create_table :committee_meetings do |t|
      t.datetime :date
      t.integer :status
      t.integer :type

      t.timestamps
    end
  end
end
