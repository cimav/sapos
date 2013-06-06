class ApplicantsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def show
    @applicant = Applicant.find(params[:id])
    @programs     = Program.where(:program_type=>2).order('name')
    @institutions = Institution.order('name')
    @staffs       = Staff.select("id,first_name,last_name").order("first_name")
    @campus = Campus.order('name')
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

    @campus = Campus.order('name')
  end

  def live_search
    @applicants = Applicant.order("first_name")

    if params[:program] != '0' then
      @applicants = @applicants.where(:program_id => params[:program])
    end
    
    if params[:status] != '0' then
      @applicants = @applicants.where(:status => params[:status])
    end
    
    if params[:campus] != '0' then
      @applicants = @applicants.where(:campus_id => params[:campus])
    end

    if !params[:q].blank?
      @applicants = @applicants.where("(CONCAT(first_name,' ',primary_last_name) LIKE :n OR id LIKE :n)",{:n => "%#{params[:q]}%"})
    end    

    respond_with do |format|
      format.html do 
        render :layout => false
      end
      format.xls do 
        rows = Array.new
        @applicants.collect do |s|
          rows << {'Folio' => s.folio,
                   'Nombre' => s.first_name,
                   'Primer_Apellido' => s.primary_last_name,
                   'Segundo_Apellido' => s.second_last_name,
	           "Fecha_Nac" => s.date_of_birth,
                   "Estado_Civil" => (Applicant::CIVIL_STATUS[s.civil_status] rescue ''),
                   'Programa' => (s.program_id==0 ? 'Otro' : s.program.name),
                   "Campus"   => (s.campus.name rescue '')
                   "Institucion_Anterior" => (s.previous_institution==0 ? 'Otras' : (Institution.find(s.previous_institution).full_name rescue '')),
                   "Promedio" => s.average,
                   "Telefono" => s.phone,
                   "Celular" => s.cell_phone,
                   "Direccion" => s.address,
                   'Asesor' => (Staff.find(s.staff_id).full_name rescue ''),
                  }
        end 
        column_order = ["Folio","Nombre","Primer_Apellido","Segundo_Apellido","Fecha_Nac","Estado_Civil","Programa","Institucion_Anterior","Promedio","Telefono","Celular","Direccion","Asesor"]
        to_excel(rows,column_order,"Aspirantes","Aspirantes")
      end 
    end 
  end


  def new
    @programs     = Program.where(:program_type=>2).order('name')
    @applicant    = Applicant.new
    @institutions = Institution.order('name')
    @staffs       = Staff.select("id,first_name,last_name").order("first_name")
    @campus       = Campus.order('name')

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
    parameters = {}
    @applicant = Applicant.find(params[:id])
    
    if !@applicant.student_id.nil?
      parameters[:student_id] = @applicant.student_id
      render_error @applicant, "El aspirante ya esta registrado como alumno, no se puede modificar",parameters
      return
    end

    if @applicant.update_attributes(params[:applicant])
      @message = "Aspirante actualizado."

      if @applicant.status == 3 and @applicant.program_id != 0
        if accepted_applicant_register @applicant
           parameters[:student_id] = @applicant.student_id
           parameters[:status] = 3
           @message = "Aspirante actualizado e inscrito"
        else
          @applicant.errors.add(:base,"Error al crear el estudiante")
          render_error @applicant, "No se pudo inscribir al aspirante",parameters
          return
        end
      end

      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Applicant: #{@applicant.id},#{@applicant.first_name} #{@applicant.primary_last_name}"}).save
      render_message @applicant,@message,parameters
    else
      render_error @applicant, "Error al actualizar estudiante",parameters
    end
  end
  
  def accepted_applicant_register (applicant)
    @student = Student.new()
    @student.first_name = applicant.first_name 
    @student.last_name  = "#{applicant.primary_last_name} #{applicant.second_last_name}"
    @student.campus_id  = applicant.campus_id 
    @student.program_id = applicant.program_id
    @student.previous_institution = applicant.previous_institution
    @student.supervisor = applicant.staff_id
    @student.start_date = Time.now
  
   
    if @student.save 
      applicant.update_attribute(:student_id,@student.id)
      return true
    else
      logger.debug "NOOOOOOOOOOO: #{@student.errors.full_messages}"
      @applicant.errors.add(:base,@student.errors.full_messages)
      @applicant.
      return false
    end
  end
  
  def files
    @applicant = Applicant.find(params[:id])
    @applicant_files = ApplicantFile.where(:applicant_id=>params[:id])
    render :layout=> "standalone"
  end

  def upload_file
    json = {}
    f = params[:applicant_file]['file']

    @applicant_file = ApplicantFile.new
    @applicant_file.applicant_id = params[:applicant_id]
    @applicant_file.file_type = params[:file_type]
    @applicant_file.file = f
    @applicant_file.description = f.original_filename

    if @applicant_file.save
      render :inline => "<status>1</status><reference>upload</reference><id>#{@applicant_file.id}</id>"
    else
      render :inline => "<status>0</status><reference>upload</reference><errors>#{@applicant_file.errors.full_messages}</errors>"
    end 
  rescue  
    render :inline => "<status>0</status><reference>upload</reference><errors>Error general</errors>"
  end

  def  download_file
    af = ApplicantFile.find(params[:id]).file
    send_file af.to_s, :x_sendfile=>true
  end

  def render_error(object,message,parameters)
    flash = {}
    flash[:error] = message
    respond_with do |format|
      format.html do 
        if request.xhr?
          json = {}
          json[:flash] = flash
          json[:errors] = object.errors
          json[:errors_full] = object.errors.full_messages
          json[:params] = parameters
          render :json => json, :status => :unprocessable_entity
        else
          redirect_to object
        end
      end
    end
  end

  def render_message(object,message,parameters)
    flash = {}
    flash[:notice] = message
    respond_with do |format|
      format.html do
        if request.xhr?
          json = {}
          json[:flash] = flash
          json[:uniq]  = object.id
          json[:params] = parameters
          render :json => json
        else
          redirect_to object
        end
      end
    end
  end
end
