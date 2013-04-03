class ApplicantsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def show
    @applicant = Applicant.find(params[:id])
    @programs     = Program.where(:program_type=>2).order('name')
    @institutions = Institution.order('name')
    render :layout => false
  end

  def index
    if current_user.program_type == Program::ALL
      @programs     = Program.where(:program_type=>2).order('name')
      @program_type = Program::PROGRAM_TYPE.invert.sort {|a,b| a[1] <=> b[1] }
    else
      @programs     = Program.joins(:permission_user).where(:permission_users=>{:user_id=>current_user.id},:program_type=>2).order('name')
      @program_type = { Program::PROGRAM_TYPE[current_user.program_type] => current_user.program_type }
    end
  end

  def live_search
    @applicants = Applicant.order("first_name")

    if params[:program] != '0' then
      @applicants = @applicants.where(:program_id => params[:program])
    end
    
    if params[:status] != '0' then
      @applicants = @applicants.where(:status => params[:status])
    end

    if !params[:q].blank?
      @applicants = @applicants.where("(CONCAT(first_name,' ',primary_last_name) LIKE :n OR id LIKE :n)",{:n => "%#{params[:q]}%"})
    end    


    render :layout => false
  end


  def new
    @programs     = Program.where(:program_type=>2).order('name')
    @applicant = Applicant.new
    @institutions = Institution.order('name')

    render :layout => false
  end

  def create
    flash = {}
    @applicant = Applicant.new(params[:applicant])

    if @applicant.save
      flash[:notice] = "Aspirante registrado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Create Applicant: #{@applicant.id},#{@applicant.first_name} #{@applicant.primary_last_name}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @applicant.id
            render :json => json
          else 
            redirect_to @applicant
          end
        end
      end
    else
      flash[:error] = "Error al crear aspirante."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash]  = flash
            json[:errors] = @applicant.errors
            json[:errors_full] = @applicant.errors.full_messages
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @applicant
          end
        end
      end
    end
  end

  def update
    flash = {}
    @applicant = Applicant.find(params[:id])
    if @applicant.update_attributes(params[:applicant])
      flash[:notice] = "Aspirante actualizado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Applicant: #{@applicant.id},#{@applicant.first_name} #{@applicant.primary_last_name}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq]  = @applicant.id
            render :json => json
          else
            redirect_to @applicant
          end
        end
      end
    else
      flash[:error] = "Error al crear aspirante."
      respond_with do |format|
        format.html do
          if request.xhr? 
            json = {}
            json[:flash]  = flash
            json[:errors] = @applicant.errors
            json[:errors_full] = @applicant.errors.full_messages
            render :json => json, :status=> :unprocessable_entity
          else
            redirect_to @applicant
          end
        end
      end
    end
  end
end