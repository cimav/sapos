class AddColumnsToTerms < ActiveRecord::Migration
  def self.up
    add_column :terms, :advance_start_date, :date
    add_column :terms, :advance_end_date, :date
  end

  def self.down
    remove_column :terms, :advance_start_date
    remove_column :terms, :advance_end_date
  end
end
