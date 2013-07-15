class AddGradeDateToTerms < ActiveRecord::Migration
  def self.up
    add_column :terms, :grade_start_date, :date
    add_column :terms, :grade_end_date, :date
  end

  def self.down
    remove_column :terms, :grade_start_date
    remove_column :terms, :grade_end_date
  end
end
