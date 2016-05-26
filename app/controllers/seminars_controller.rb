class SeminarsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
    @user = User.find(current_user.id)
    if @user.access.in? [1,5] ## Administrator or Manager
      @supervisors = Staff.where(:status=>0)
    elsif @user.access.in? [2]  ## Operator
      @supervisors = Staff.where(:status=>0,:area_id=>(eval @user.areas))
    end
  end

  def live_search
    @user = User.find(current_user.id)

    if @user.access.in? [1,5] ## Administrator or Manager
      @seminars = Advance.where(:status=>'P')
    elsif @user.access.in? [2]  ## Operator
      @seminars = Advance.joins(:student=>:staff_supervisor).where(:status=>'P').where("staffs.area_id=?",(eval @user.areas))
    end

    if !params[:q].blank?
      @seminars = @seminars.joins(:student).where("(CONCAT(first_name,' ',last_name) LIKE :n OR card LIKE :n)", {:n => "%#{params[:q]}%"})
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
    render :layout => false
  end
end
