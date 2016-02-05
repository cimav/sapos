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
    if !params[:status_borrados].to_i.eql? 1
      @applicants = @applicants.where("status<>?",Applicant::DELETED)
    end

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
                   "Campus"   => (s.campus.name rescue ''),
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
    
    @message = "Aspirante actualizado."
    @activity_log = ""
    @old_folio = @applicant.folio
    @applicant.attributes = params[:applicant]
    if @applicant.program_id_changed?
      #Recalcular folio
      @applicant.update_folio
      @new_folio = @applicant.folio
      @activity_log = "Update Applicant Folio: #{@applicant.id},#{@applicant.first_name} #{@applicant.primary_last_name}, Old Folio: #{@old_folio},New Folio:#{@new_folio}"
      parameters[:folio] = @applicant.folio
      @message = "#{@message} \n Folio Recalculado"
    end

    if @applicant.update_attributes(params[:applicant])

      if (@applicant.status.to_i.eql? 3 or  @applicant.status.to_i.eql? 5) and @applicant.program_id != 0
        if accepted_applicant_register @applicant
           parameters[:student_id] = @applicant.student_id
           parameters[:status] = @applicant.status
           @message = "Aspirante actualizado e inscrito"
        else
          @applicant.errors.add(:base,"Error al crear el estudiante")
          render_error @applicant, "No se pudo inscribir al aspirante",parameters
          return
        end
      end

      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Applicant: #{@applicant.id},#{@applicant.first_name} #{@applicant.primary_last_name}"}).save

      if !@activity_log.blank?
        ActivityLog.new({:user_id=>current_user.id,:activity=>@activity_log}).save
      end
      render_message @applicant,@message,parameters
    else
      render_error @applicant, "Error al actualizar estudiante",parameters
    end
  end
  
  def accepted_applicant_register (applicant)
    @student                      = Student.new()
    @student.first_name           = applicant.first_name
    @student.last_name            = "#{applicant.primary_last_name} #{applicant.second_last_name}"
    @student.campus_id            = applicant.campus_id
    @student.previous_institution = applicant.previous_institution
    @student.previous_degree_desc = applicant.previous_degree_type
    @student.supervisor           = applicant.staff_id
    @student.date_of_birth        = applicant.date_of_birth
    @student.email                = applicant.email
    @student.start_date           = Time.now
 
    if applicant.status.eql? 5
      if applicant.program_id.eql? 1
        @student.program_id = 6
      elsif applicant.program_id.eql? 3
        @student.program_id = 7
      else
        @student.program_id           = applicant.program_id
      end
    else
      @student.program_id           = applicant.program_id
    end

    if @student.save 
      applicant.update_attribute(:student_id,@student.id)
      @student.contact.home_phone   = applicant.phone
      @student.contact.mobile_phone = applicant.cell_phone
      @student.contact.address1     = applicant.address
      @student.contact.save
      return true
    else
      @applicant.errors.add(:base,@student.errors.full_messages)
      return false
    end
  end
  
  def files
    @applicant = Applicant.find(params[:id])
    @applicant_files = ApplicantFile.where(:applicant_id=>params[:id])
    render :layout=> "standalone"
  rescue ActiveRecord::RecordNotFound
    @error = 1
    render :template=>"applicants/errors",:layout=> "standalone"
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

  def certificates
    @applicant = Applicant.find(params[:id])
    time = Time.new
    year = time.year.to_s
    dir  = t(:directory)   

    title = dir[:posgrado_chief][:title]
    name  = dir[:posgrado_chief][:name]
    job   = dir[:posgrado_chief][:job]
    @firma  = "#{title} #{name}"
    @puesto = "#{job}"
   
    if params[:type] == "aceptacion"
      @consecutivo = get_consecutive(@applicant, time, Certificate::APP_ACCEPTANCE)
      @rails_root  = "#{Rails.root}"
      @year_s      = year[2,4]
      @year        = year
      @days        = time.day.to_s
      @month       = get_month_name(time.month)
      @nombre      = @applicant.full_name
      @programa    = @applicant.program.name
      @campus      = @applicant.campus.id
      
      @ciclo              = params[:ciclo]
      @fecha_inicio       = params[:f_ini]
      @fecha_fin          = params[:f_fin]
      @fecha_inscripcion  = params[:f_ins]
      @fecha_revision     = params[:f_rev]
      @recomendacion      = params[:rec]
      @level              = @applicant.program.level.to_i rescue 0

      @staff              = Staff.find(@applicant.staff_id) rescue nil
      @supervisor         = nil
      if !@staff.nil? 
        @supervisor         = "#{@staff.title} #{@staff.full_name}"
      end

      html = "Error"
      if @applicant.status==3 # ACEPTADO
        html = render_to_string(:layout => 'certificate' , :template=> 'applicants/certificates/constancia_aceptacion')
      elsif @applicant.status==5 #PROPEDEUTICO
        html = render_to_string(:layout => 'certificate' , :template=> 'applicants/certificates/constancia_aceptacion_prop')
      elsif @applicant.status==2 # RECHAZADO
        html = render_to_string(:layout => 'certificate' , :template=> 'applicants/certificates/constancia_rechazo')
      end

      kit = PDFKit.new(html, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
      filename = "carta-aspirante-#{@applicant.id}.pdf"
      send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
      return
    end
  end



  def  download_file
    af = ApplicantFile.find(params[:id]).file
    send_file af.to_s, :x_sendfile=>true
  end

  
  def get_consecutive(object, time, type)
    maximum = Certificate.where(:year => time.year).maximum("consecutive")

    if maximum.nil?
      maximum = 1
    else
      maximum = maximum + 1 
    end
 
    certificate                 = Certificate.new()
    certificate.consecutive     = maximum
    certificate.year            = time.year
    certificate.attachable_id   = object.id
    certificate.attachable_type = object.class.to_s
    certificate.type            = type
    certificate.save

    return "%03d" % maximum
  end
  
  def get_month_name(number)
    months = ["enero","febrero","marzo","abril","mayo","junio","julio","agosto","septiembre","octubre","noviembre","diciembre"]
    name = months[number - 1]
    return name
  end
end
