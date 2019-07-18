class AddPreviousDegreeEndDateToStudents < ActiveRecord::Migration
  def change
  	add_column :students, :previous_degree_start_date, :date
  end
end
