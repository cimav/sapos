class AddNotesToGraduates < ActiveRecord::Migration
  def self.up
    add_column :graduates, :notes, :text
  end

  def self.down
    remove_column :graduates, :notes
  end
end
