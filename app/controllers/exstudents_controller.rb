class ExstudentsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
    if current_user.campus_id == 0
      @campus     = Campus.order('name')
      @all_campus = 1
    else
      @campus = Campus.joins(:user).where(:users=>{:id=>current_user.id})
      @all_campus = 0
    end

    if current_user.program_type == Program::ALL
      @programs     = Program.order('name')
      @program_type = Program::PROGRAM_TYPE.invert.sort {|a,b| a[1] <=> b[1] }
    else
      @programs     = Program.joins(:permission_user).where(:permission_users=>{:user_id=>current_user.id}).order('name')
      @program_type = { Program::PROGRAM_TYPE[current_user.program_type] => current_user.program_type }
    end

    @supervisors = Staff.find_by_sql "SELECT id, first_name, last_name FROM staffs WHERE id IN (SELECT supervisor FROM students UNION SELECT co_supervisor FROM students) ORDER BY first_name, last_name"
  end

  def show
    @exstudent = Exstudent.find(params[:id])
    @student  = Student.find(@exstudent.student_id)
    render :layout => false
  end


end
