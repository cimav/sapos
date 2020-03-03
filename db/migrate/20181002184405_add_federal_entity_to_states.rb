class AddFederalEntityToStates < ActiveRecord::Migration
  def change
    add_column :states, :federal_entity, :integer
  end
end
