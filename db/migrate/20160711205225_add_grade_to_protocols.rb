class AddGradeToProtocols < ActiveRecord::Migration
  def change
    add_column :protocols, :grade, :decimal, :precision => 8, :scale => 2
  end
end
