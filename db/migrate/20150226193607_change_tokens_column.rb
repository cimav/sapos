class ChangeTokensColumn < ActiveRecord::Migration
  def up
    change_column :tokens, :attachable_type, :string
  end

  def down
    change_column :tokens, :attachable_type, :integer
  end
end
