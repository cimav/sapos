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
  end#index

  def show
    @exstudent = Exstudent.find(params[:id])
    @student  = Student.find(@exstudent.student_id)
    render :layout => false
  end#show

  def live_search
    extra_where = ""
    where_hash  = {:status=>[2,5],:programs=>{:level=>[1,2]}}  ## hash de busqueda por default

    if !(params[:q].to_i.eql? 0)  ## busqueda por id
      where_hash[:exstudents]= {:id=>params[:q]}
      params[:q] = ""
    end

    if !(params[:program].to_i.eql? 0)  ## busqueda por programa
      where_hash[:program_id]= params[:program]     ## agregamos al hash el program id
    end

    if !(params[:program_type].to_i.eql? 0) ## busqueda por tipo de programa
      where_hash[:programs][:program_type]= params[:program_type]  ## agregamos al hash el program_type
    end

    if !(params[:campus].to_i.eql? 0)  ## busqueda por campus
      where_hash[:campus_id] = params[:campus]
    end
    
    if !(params[:estatus].to_i.eql? 0)  ## busqueda por campus
      if params[:estatus].to_i.eql? 1
        extra_where = "exstudents.id is not null"
      elsif params[:estatus].to_i.eql? 2
        extra_where = "exstudents.id is null"
      end
    end
    
    if !params[:q].empty? ## si el campo llega vacío se va al else
      q = params[:q]
      if extra_where.empty?
        @students = Student.includes(:program,:exstudent).where(where_hash).where("CONCAT(first_name,' ',last_name) like '%"+q+"%'")
      else
        @students = Student.includes(:program,:exstudent).where(where_hash).where("CONCAT(first_name,' ',last_name) like '%"+q+"%'").where(extra_where)
      end        
    else
      if extra_where.empty?
        @students = Student.includes(:program,:exstudent).where(where_hash)
      else
        @students = Student.includes(:program,:exstudent).where(where_hash).where(extra_where)
      end
    end

    render :layout => false
  end#live_search

  def analizer
      @exstudent = Exstudent.where(:student_id=>params[:student_id])
    if @exstudent.size > 0
      redirect_to :action => 'show', :id=>@exstudent[0].id
    else 
      redirect_to :action => 'new', :id=>params[:student_id]
    end
  end#analizer

  def new
    @student = Student.find(params[:id])
    @dialog  = params[:dialog]

    render :layout => false
  end#new

  def create
    parameters = {}

    @exstudent        = Exstudent.new(params[:exstudent])
    
    if @exstudent.save
      render_message(@exstudent,"Alta de sesión exitosa",parameters)
    else
      puts @exstudent.errors.full_messages
      render_error(@exstudent,"Error al dar de alta la sesión",parameters)
    end
  end# create

  def update
    parameters = {}
    @exstudent = Exstudent.find(params[:id])

    if @exstudent.update_attributes(params[:exstudent])
      render_message(@exstudent,"Registro actualizado",parameters)
    else
      render_error(@exstudent,"Error al actualizar",parameters)
    end
  end#update

  def get_percentage
    @exstudent = Exstudent.find(params[:id]) rescue nil
    if @exstudent.nil?
      render :text => "-1"
    else
      render :text => @exstudent.percentage.round(0)
    end
  end  
end
