class AddNotesToApplicants < ActiveRecord::Migration
  def self.up
    add_column :applicants, :notes, :text
  end

  def self.down
    remove_column :applicants, :notes
  end
end
