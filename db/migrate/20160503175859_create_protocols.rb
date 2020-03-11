class CreateProtocols < ActiveRecord::Migration
  def change
    create_table :protocols do |t|
      t.references :advance
      t.references :staff
      t.integer :group
      t.integer :grade
      t.integer :status
      t.timestamps
    end
  end
end
