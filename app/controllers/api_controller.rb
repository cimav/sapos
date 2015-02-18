class ApiController < ApplicationController
  def active_students
    @staff = Staff.find_by_email(params['email'])
    
    students = @staff.active_students
    render json: students
    
  end
end
