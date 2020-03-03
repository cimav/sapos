class CreateCommitteeMembers < ActiveRecord::Migration
  def change
    create_table :committee_members do |t|
      t.references :staff
      t.integer :status

      t.timestamps
    end
    add_index :committee_members, :staff_id
  end
end
