# coding: utf-8
class SeminarsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
    @user = User.find(current_user.id)
    if @user.access.in? [1,5] ## Administrator or Manager
      @supervisors = Staff.where(:status=>0)
    elsif @user.access.in? [2]  ## Operator
      @supervisors = Staff.where(:status=>0,:area_id=>(eval @user.areas))
    else
      render :text => "Usted no tiene permisos para este módulo"
    end
  end

  def live_search
    @user = User.find(current_user.id)

    if @user.access.in? [1,5] ## Administrator or Manager
      @seminars = Advance.where(:advance_type=>3, :status=>'P')
    elsif @user.access.in? [2]  ## Operator
      @seminars = Advance.joins(:student=>:staff_supervisor).where(:advance_type=>3,:status=>'P').where("staffs.area_id=?",(eval @user.areas))
    end

    if !params[:q].blank?
      if params[:q].to_i != 0
        @seminars = @seminars.where("advances.id = ?",params[:q].to_i)
      else
        @seminars = @seminars.joins(:student).where("(CONCAT(first_name,' ',last_name) LIKE :n OR card LIKE :n)", {:n => "%#{params[:q]}%"})
      end
    end
    render :layout => false
  end

  def get_advance
    @advance = Advance.find(params[:id])
    render :layout => false
  end
   
  def new
    @user = User.find(current_user.id)
    if @user.access.in? [1,5] ## Administrator or Manager
      @students= Student.where(:status=>1)
    elsif @user.access.in? [2]  ## Operator
      @students= Student.joins(:staff_supervisor).where(:status=>1).where("staffs.area_id=?",(eval @user.areas))
    end
    render :layout => false
  end

  def advance_data
    @student = Student.find(params[:advance][:student_id])
    @staffs  = Staff.where(:status=>0)
    render :layout => false
  end

  def create
    parameters = {}
    @advance  = Advance.new(params[:advance])

    if @advance.save
      render_message(@advance,"Seminario departamental creado con éxito",parameters)
    else
      render_error(@advance,"Error al guardar seminario departamental",parameters)
    end
  end
end
