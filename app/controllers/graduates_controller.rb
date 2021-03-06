class GraduatesController < ApplicationController
  load_and_authorize_resource
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
  

  def live_search
    if current_user.program_type==Program::ALL
      @students = Student.where("status IN (#{Student::GRADUATED}, #{Student::FINISH})").order("first_name").includes(:program)
    else
      @students = Student.joins(:program => :permission_user).where(:permission_users=>{:user_id=>current_user.id} ).order("first_name").includes(:program)
      @students = @students.where("status IN (#{Student::GRADUATED}, #{Student::FINISH})").order("first_name").includes(:program)
    end

    if params[:program_type] != '0' then
      @students = @students.joins(:program).where(:programs=>{:program_type=>params[:program_type]})
    end

    if params[:program] != '0' then
      @students = @students.where(:program_id => params[:program])
    end 
     
    if current_user.campus_id != 0 
      params[:campus] = current_user.campus_id
    end

    if params[:campus] != '0' then
      @students = @students.where(:campus_id => params[:campus])
    end 

    if params[:supervisor] != '0' then
      @students = @students.where("(supervisor = :supervisor OR co_supervisor = :supervisor)", {:supervisor => params[:supervisor]}) 
    end

    if !params[:q].blank?
      if is_number(params[:q])
        logger.info "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        @students = @students.where("id=?", params[:q])
      else
        logger.info "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
        @students = @students.where("(CONCAT(first_name,' ',last_name) LIKE :n)", {:n => "%#{params[:q]}%"}) 
      end
    end

    

    s = []

    if !params[:status_activos].blank?
      s << params[:status_activos].to_i
    end

    if !params[:status_egresados].blank?
      s << params[:status_egresados].to_i
    end

    if !params[:status_bajas].blank?
      s << params[:status_bajas].to_i
    end

    if !s.empty?
      @students = @students.where("status IN (#{s.join(',')})")
    end

    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.xls do
        rows = Array.new
        @students.collect do |s|
          rows << {'Matricula' => s.card,
                   'Nombre' => s.first_name, 
                   'Apellidos' => s.last_name, 
                   'Email' => s.email,
                   'Estado' => s.status_type,
	           "Fecha_Nac" => s.date_of_birth,
	           "Ciudad_Nac" => s.city,
	           "Estado_Nac" => (s.state.name rescue ''),
	           "Pais_Nac" => (s.country.name rescue ''),
	           "Campus" => (s.campus.name rescue ''),
                   'Programa' => s.program.name,
                   'Asesor' => (Staff.find(s.supervisor).full_name rescue ''),
                   'Lugar_de_trabajo' => (s.graduate.workplace rescue ''),
                   'Ingresos' => (Graduate::INCOMES[s.graduate.income] rescue ''),
                   'Giro' => (Graduate::GYRE[s.graduate.gyre] rescue ''),
                   'Premios' => (s.graduate.prizes rescue ''),
                   'SNI' => (s.graduate.sni rescue ''),
                   'Estatus_SNI' => (Graduate::SNI_STATUS[s.graduate.sni_status] rescue ''),
                   'Estudios_Subsecuentes' => (s.graduate.subsequent_studies rescue ''),
                   'Del' => (s.start_date rescue ''),
                   'Al' => (s.thesis.defence_date rescue ''),
                   'Tesis' => (s.thesis.title rescue '')
                   }
        end
        column_order = ["Matricula", "Nombre", "Apellidos", "Estado", "Email", "Fecha_Nac", "Ciudad_Nac", "Estado_Nac", "Pais_Nac", "Campus", "Programa", "Asesor", "Lugar_de_trabajo","Ingresos","Giro","Premios","SNI","Estatus_SNI","Estudios_Subsecuentes","Del","Al","Tesis"]
        to_excel(rows, column_order, "Estudiantes", "Estudiantes")
      end
    end
  end

  def analizer
    @graduate = Graduate.where(:student_id=>params[:student_id])
    if @graduate.size > 0
      redirect_to :action => 'show', :id=>@graduate[0].id
    else 
      redirect_to :action => 'new', :id=>params[:student_id]
    end
  end
  
  def show
    @graduate = Graduate.find(params[:id]) 
    @student  = Student.find(@graduate.student_id)
    render :layout => false
  end

  def new
    @student = Student.find(params[:id])
    @dialog  = params[:dialog]
    render :layout => false
  end

  def create
    flash = {}
    @graduate = Graduate.new(params[:graduate])

    if @graduate.save
      flash[:notice] = "Datos Guardados Correctamente"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @graduate.student_id
            render :json => json
          else
            redirect_to @graduate
          end
        end
      end
    else
      flash[:error] = "Error al crear estudiante."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors_full] = @graduate.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @graduate
          end
        end
      end
    end
  end

  def update
    flash = {}
    @graduate = Graduate.find(params[:id])

    if @graduate.update_attributes(params[:graduate])
      flash[:notice] = "Registro actualizado."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else
            redirect_to @graduate
          end
        end
      end
    else
      flash[:error] = "Error al actualizar"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @graduate.errors
            json[:errors_full] = @graduate.errors.full_messages
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @graduate
          end
        end
      end
    end


  end

  def ready
    render :layout => false
  end

private
  def is_number(my_string)
    true if Float(my_string) rescue false
  end 
end
