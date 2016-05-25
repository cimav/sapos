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
    @seminars = Advance.where(:status=>'P')
    render :layout => false
  end
end
