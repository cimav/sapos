class AddScholarshipTypeToStudents < ActiveRecord::Migration
  def change
    add_column :students, :scholarship_type, :integer
    add_column :students, :student_time, :integer
  end
end
