class AddStudentIdToApplicants < ActiveRecord::Migration
  def self.up
    add_column :applicants,:student_id,:integer
  end

  def self.down
    remove_column :applicants, :integer
  end
end
