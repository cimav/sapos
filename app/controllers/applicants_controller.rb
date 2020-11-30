# coding: utf-8

require 'digest/md5'

class ApplicantsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json
  before_filter :set_locale
  before_filter :auth_required, :except=>[:register,:new_register,:get_campus,:files_register,:upload_file_register,:download_app_file,:data,:update_register,:applicant_logout]
  before_filter :auth_indigest, :only=>[:data,:update_register,:files_register,:upload_file_register,:download_app_file]

  def show
    @applicant    = Applicant.find(params[:id])
    @programs     = Program.where(:program_type=>2).order('name')
    @institutions = Institution.order('name')
    @staffs       = Staff.select("id,first_name,last_name").order("first_name")
    @campus       = Campus.order('name')
    @places       = Applicant::PLACES.invert.sort {|a,b| a[1] <=> b[1]}
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

    @config = User.where(:email=>'SYSTEM').first.config rescue nil
    @campus = Campus.order('name')
  end

  def live_search
    @applicants            = Applicant.order("created_at")
 
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
                   "Sede"     => (Applicant::PLACES[s.place_id] rescue ''),
                   "Institucion_Anterior" => (s.previous_institution==0 ? 'Otras' : (Institution.find(s.previous_institution).full_name rescue '')),
                   "Promedio" => s.average,
                   "Telefono" => s.phone,
                   "Celular" => s.cell_phone,
                   "Direccion" => s.address,
                   "Email" => s.email,
                   'Asesor' => (Staff.find(s.staff_id).full_name rescue ''),
                   'Fecha_Registro' => s.created_at.to_date,
                  }
        end 
        column_order = ["Folio","Nombre","Primer_Apellido","Segundo_Apellido","Fecha_Nac","Estado_Civil","Programa","Campus","Sede","Institucion_Anterior","Promedio","Telefono","Celular","Direccion","Email","Asesor","Fecha_Registro"]
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
    @applicant.status = 1

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

  def register
    @include_js   = "applicants.register.js"
    @t = t(:applicants)
    @programs     = Program.where(:program_type=>2).order('name')
    @places       = Applicant::PLACES.invert.sort {|a,b| a[1] <=> b[1] }
    @config       = User.where(:email=>'SYSTEM').first.config rescue nil
    @active       = @config[:applicants][:form_status] rescue nil
    @countries    = Country.order('name')


    @countries_ordered = Array.new 
    @countries_ordered.push(["México",146])

    @countries.each_with_index do |c,index|
      @countries_ordered.push([c.name,c.id])
    end

    render :layout => 'standalone'
  end
  
  def data
    @t            = t(:applicants)
    @include_js   = "applicants.register.js"
    @programs     = Program.where(:program_type=>2).order('name')
    @places       = Applicant::PLACES.invert.sort {|a,b| a[1] <=> b[1] }
    @institutions = Institution.order('name')
    @staffs       = Staff.select("id,first_name,last_name").where(:institution_id=>1,:status=>0).order("first_name")
    @applicant    = Applicant.find(session[:applicant_user])
    @countries    = Country.order('name')

    
    program_id = @applicant.program_id
    if program_id.to_i.eql? 1  ##MCM
      @campus = Campus.select("id,name").find([1,2])
    elsif program_id.to_i.eql? 2 ##DCM
      @campus = Campus.select("id,name").find([1,2])
    elsif program_id.to_i.eql? 3 ## MCTA
      @campus = Campus.select("id,name").find([1,4])
    elsif program_id.to_i.eql? 4 ## DCTA
      @campus = Campus.select("id,name").find([1,4])
    elsif program_id.to_i.eql? 10 ## DN
      @campus = Campus.select("id,name").find([2])
    elsif program_id.to_i.eql? 15 ## MCM DOBLE
      @campus = Campus.select("id,name").find([1,2])
    end
    render :layout => 'standalone'
  end
 
  def get_campus
    program_id = params[:program_id]
    json = {}
    @campus= []
    if program_id.to_i.eql? 1  ##MCM
      @campus = Campus.select("id,name").find([1,2])
    elsif program_id.to_i.eql? 2 ##DCM
      @campus = Campus.select("id,name").find([1,2])
    elsif program_id.to_i.eql? 3 ## MCTA
      @campus = Campus.select("id,name").find([1,4])
    elsif program_id.to_i.eql? 4 ## DCTA
      @campus = Campus.select("id,name").find([1,4])
    elsif program_id.to_i.eql? 10 ## DN
      @campus = Campus.select("id,name").find([2])
    elsif program_id.to_i.eql? 15 ## MCM Doble
      @campus = Campus.select("id,name").find([1,2])
    end
    json[:campus] = @campus
    #render :layout => 'standalone'
    render :json => json
  end


  def new_register
    flash = {}
    @applicant = Applicant.new(params[:applicant])
    @applicant.status = 7  ### REQUEST_PASS
    @applicant.password = SecureRandom.base64(12)
    #@applicant = Applicant.find(355)
    #create_document(@applicant)

#=begin
    if @applicant.save
      flash[:notice] = "Aspirante registrado correctamente."

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

      content = "{:applicant_id=>\"#{@applicant.id}\",:view=>29}"
      send_email(@applicant.email,"Solicitud nuevo ingreso CIMAV",content,@applicant)
      content = "{:applicant_id=>\"#{@applicant.id}\",:view=>30}"
      send_email(Settings.school_services1,"Un aspirante ha solicitado password",content,@applicant)
      #send_email(Settings.school_services2,"Un aspirante ha solicitado password",content,@applicant)
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
#=end
  end

  def update_register
    parameters = {}
    @applicant = Applicant.find(session[:applicant_user])
    @message = "Aspirante actualizado."
    if @applicant.update_attributes(params[:applicant])
      render_message @applicant,@message,parameters
    else
      render_error @applicant, "Error al actualizar estudiante",parameters
    end
  end

  def create_document(a) ## a for applicant
    @r_root  = Rails.root.to_s
    @rectangles = false
    @doctorates = [2,4,10]
    
    today = Date.today

    filename  = "private/files/applicants/#{a.id}"
    pdf_route = "#{filename}/solicitud_nuevo.pdf"
    FileUtils.mkdir_p(filename) unless File.directory?(filename)
    
    if !File.exist?(pdf_route)
      pdf = Prawn::Document.new(:margin=>20)
      ## SET LOGO
      image = "#{Rails.root}/app/assets/images/pdf-logo-card.jpg"
      y = 750
      pdf.image image, :at => [70,y], :height => 80
      
      ## SET TITLE
      x = 10
      y = y - 90
      w = 550
      h = 20
      size = 19
      text = "Solicitud de ingreso a posgrado"
      if @rectangles then pdf.stroke_rectangle [x,y], w, h end
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :center
      
      ## SET DATE
      y = y - 30
      h = 13
      size = 12
      text = "Chihuahua, Chihuahua a #{today.day} de #{get_month_name(today.month)} de #{today.year}"
      if @rectangles then pdf.stroke_rectangle [x,y], w, h end
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :normal, :align=> :right, :inline_format=>true
  
      pdf.move_down 150
      data= []
      data << [{:content=>"<b>Datos Solicitud</b>",:colspan=>2,:align=>:center}]
      data << ["<b>Programa:</b>",a.program.name]
      data << ["<b>Campus:</b>",a.campus.name]
      if !(@doctorates.include? a.program_id)
        data << ["<b>Sede:</b>",Applicant::PLACES[a.place_id]]
      else
        staff_name = Staff.find(a.staff_id).full_name rescue ""
        data << ["<b>Asesor:</b>",staff_name]
      end
      tabla = pdf.make_table(data,:width=>530,:cell_style=>{:size=>12,:padding=>2,:inline_format => true,:border_width=>1},:position=>:center,:column_widths=>[130,400])
      tabla.draw
      
      pdf.move_down 20
      data= []
      data << [{:content=>"<b>Datos Personales</b>",:colspan=>2,:align=>:center}]
      data << ["<b>Nombre:</b>",a.full_name]
      data << ["<b>Correo Electrónico:</b>",a.email]
      data << ["<b>Telefono:</b>",a.phone]
      data << ["<b>Celular:</b>",a.cell_phone]
      data << ["<b>Dirección:</b>",a.address]
      data << ["<b>Estado Civil:</b>",Applicant::CIVIL_STATUS[a.civil_status]]
      data << ["<b>Grado Anterior:</b>",a.previous_degree_type]
      data << ["<b>Institucion de origen:</b>",(Institution.find(a.previous_institution).name rescue "N.D.")]
      data << ["<b>Promedio:</b>",a.average]
      tabla = pdf.make_table(data,:width=>530,:cell_style=>{:size=>12,:padding=>2,:inline_format => true,:border_width=>1},:position=>:center,:column_widths=>[130,400])
      tabla.draw
  
      pdf.move_down 20
      data= []
      data << [{:content=>"<b>Documentos</b><br>",:colspan=>4,:align=>:center}]
  
      @applicant_files = ApplicantFile.where(:applicant_id=>a.id)
  
      content1 = pdf.table_icon('fa-square-o')
      content2 = pdf.table_icon('fa-square-o')
      if @applicant_files.where(:file_type=>ApplicantFile::BIRTH_CERTIFICATE).size > 0
        content1 = pdf.table_icon('fa-check-square-o')
      end
      if @applicant_files.where(:file_type=>ApplicantFile::PREVIOUS_DEGREE_TEST_CERTIFICATE).size > 0
        content2 = pdf.table_icon('fa-check-square-o')
      end
      data << [{:content=>"<b>Acta de Nacimiento:<b>",:align=>:right},content1,{:content=>"<b>Acta de exámen grado anterior:<b>",:align=>:right},content2]
  
      content1 = pdf.table_icon('fa-square-o')
      content2 = pdf.table_icon('fa-square-o')
      if @applicant_files.where(:file_type=>ApplicantFile::CURP).size > 0
        content1 = pdf.table_icon('fa-check-square-o')
      end
      if @applicant_files.where(:file_type=>ApplicantFile::PREVIOUS_DEGREE_STUDIES_CERTIFICATE).size > 0
        content2 = pdf.table_icon('fa-check-square-o')
      end
      data << [{:content=>"<b>Curp:<b>",:align=>:right},content1,{:content=>"<b>Certificado de estudios del grado anterior:<b>",:align=>:right},content2]
  
  
      content1 = pdf.table_icon('fa-square-o')
      content2 = pdf.table_icon('fa-square-o')
      if @applicant_files.where(:file_type=>ApplicantFile::PROOF_OF_ADDRESS).size > 0
        content1 = pdf.table_icon('fa-check-square-o')
      end
      if @applicant_files.where(:file_type=>ApplicantFile::ACADEMIC_CURRICULUM).size > 0
        content2 = pdf.table_icon('fa-check-square-o')
      end
      data << [{:content=>"<b>Comprobante de domicilio:<b>",:align=>:right},content1,{:content=>"<b>Curriculum académico:<b>",:align=>:right},content2]
      
      content1 = pdf.table_icon('fa-square-o')
      content2 = pdf.table_icon('fa-square-o')
      if @applicant_files.where(:file_type=>ApplicantFile::VOTING_CARD).size > 0
        content1 = pdf.table_icon('fa-check-square-o')
      end
      if @applicant_files.where(:file_type=>ApplicantFile::CONACYT_ENDED_SCHOLARSHIP_CERTIFICATE).size > 0
        content2 = pdf.table_icon('fa-check-square-o')
      end
      data << [{:content=>"<b>Credencial para votar:<b>",:align=>:right},content1,{:content=>"<b>Carta de finiquito de becario conacyt:<b>",:align=>:right},content2]
  
      content1 = pdf.table_icon('fa-square-o')
      content2 = ""
      if @applicant_files.where(:file_type=>ApplicantFile::ACADEMIC_RECOMENDATION_LETTER).size > 0
        content1 = pdf.table_icon('fa-check-square-o')
      end
      data << [{:content=>"<b>Carta de recomendación académica:<b>",:align=>:right},content1,{:content=>"",:align=>:right},content2]
      tabla = pdf.make_table(data,:width=>530,:cell_style=>{:size=>12,:padding=>2,:inline_format => true,:border_width=>0},:position=>:center)
      tabla.draw
      
      pdf.move_down 90
      pdf.text "<b>Firma del solicitante</b>", :inline_format=>true, :align=>:center
      pdf.render_file "#{pdf_route}"
   
      s = File.open("#{pdf_route}")
      @applicant_file = ApplicantFile.new
      @applicant_file.applicant_id = a.id
      @applicant_file.file_type = ApplicantFile::APPLICATION
      @applicant_file.description = "solicitud_nuevo.pdf"
      @applicant_file.file = s
      if @applicant_file.save
        a.status = 8
        a.save
        content = "{:applicant_id=>\"#{a.id}\",:view=>31}"
        send_email(Settings.school_services1,"Un aspirante ha generado su solicitud",content,a)
        #send_email(Settings.school_services2,"Un aspirante ha generado su solicitud",content,a)
      else
        logger.info "############## #{@applicant_file.errors}"
      end
    end## if file_exists

    send_file "#{filename}/solicitud_nuevo.pdf", :x_sendfile=>true
  end


  def download_app_file
    @applicant = Applicant.find(params[:applicant_id])
    create_document(@applicant)
    #send_file "#{Rails.root}/private/files/applicants/#{@applicant.id}/solicitud.pdf", :x_sendfile=>true
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
    @student.last_name            = applicant.primary_last_name
    @student.last_name2           = applicant.second_last_name
    @student.campus_id            = applicant.campus_id
    @student.previous_institution = applicant.previous_institution
    @student.previous_degree_desc = applicant.previous_degree_type
    @student.supervisor           = applicant.staff_id
    @student.date_of_birth        = applicant.date_of_birth
    @student.email                = applicant.email
    @student.curp                 = applicant.curp
    @student.start_date           = Time.now
 
    if applicant.status.eql? 5
      # 5 = Aceptado a propedeutico

      #if applicant.program_id.eql? 1
      #  @student.program_id = 6
      #elsif applicant.program_id.eql? 3
      #  @student.program_id = 7
      #else
      #  @student.program_id           = applicant.program_id
      #end
      
      # Nov 2020. Todos los programas de doctorado requieren propedeutico		
      if applicant.program_id.eql? 3 ||  applicant.program_id.eql? 4
	# Si es MCTA o DCTA, se va a PCTA
	@student.program_id = 7
      else
	# Todos los demas programas se van a PCM
	@student.program_id = 6
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
    @req_docs = ApplicantFile::REQUESTED_DOCUMENTS.clone
 
    @applicant = Applicant.find(params[:id])
    @applicant_files = ApplicantFile.where(:applicant_id=>params[:id])
    render :layout=> "standalone"
  rescue ActiveRecord::RecordNotFound
    @error = 1
    render :template=>"applicants/errors",:layout=> "standalone"
  end

  def files_register
    @t        = t(:applicants)
    
    if session[:locale].eql? "en"
      @req_docs = ApplicantFile::REQUESTED_DOCUMENTS_EN.clone
      @req_docs.delete(2)
      @req_docs.delete(11)
    else
      @req_docs = ApplicantFile::REQUESTED_DOCUMENTS.clone
    end
 
    @include_js   = "applicants.register.files.js"
    @register     = true
    #@req_docs.delete(5)
    #@req_docs.delete(8)
    #@req_docs.delete(9)
    @req_docs.delete(12)
    @req_docs.delete(13)
    #@req_docs.delete(14)
   

    @applicant = Applicant.find(session[:applicant_user])
    @applicant_files = ApplicantFile.where(:applicant_id=>session[:applicant_user])
   
   
    if @applicant.program.level.to_i.eql? 1 #maestria
      @req_docs.delete(11)
      @req_docs.delete(14)
    end
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
  
  def upload_file_register
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
     
      background = "#{Rails.root.to_s}/private/prawn_templates/membretada.png"
      atentamente = "\n\n\n\n<b>A t e n t a m e n t e\n\n\n\n#{@firma}\n#{@puesto}</b>"


      Prawn::Document.new(:background => background, :background_scale=>0.36, :margin=>[140,60,60,60] ) do |pdf|
        pdf.font_families.update(
          "Montserrat" => {       :bold        => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Bold.ttf"),
                                  :italic      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Italic.ttf"),
                                  :bold_italic => Rails.root.join("app/assets/fonts/montserrat/Montserrat-BoldItalic.ttf"),
                                  :normal      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Regular.ttf") })
        pdf.font "Montserrat"
        pdf.font_size 11
       
        city = "Chihuahua, Chih."
     
        pdf.text "<b>Coordinación de estudios de Posgrado\nOficio  PO - #{@consecutivo}/#{@year}</b>\n#{city}, a #{@days} de #{@month} de #{@year}", :inline_format=>true, :align=>:right ,:valign=>:top
       
       
        pdf.text "\n\n\n\nC. #{@nombre}\n", :align=>:left,:inline_format=>true
        pdf.text "<b>Presente.</b>\n\n", :align=>:left, :character_spacing=>4,:inline_format=>true
        
        if @applicant.status==3 # ACEPTADO
          text = "Por este conducto me es grato notificarle que ha sido aceptado como alumno de nuevo ingreso al programa <b>#{@programa}</b> para el ciclo <b>#{@ciclo}</b>. Le informo que la fecha establecida para la  inscripción de nuevo ingreso será el próximo <b>#{@fecha_inscripcion}</b>, para lo cual deberá presentarse en el área de Control Escolar de este Departamento.\n\n"
         
          text = text + "Así mismo, le informo que para el trámite de su beca nacional CONACYT deberá contar con CVU actualizado antes de la inscripción. Para mayor información ingresar a la página: <b>http://www.conacyt.gob.mx/Becas</b>\n\n"
         
          text = text + "Le envío una felicitación por este logro académico. Para cualquier duda o comentario al respecto, estoy a sus órdenes."
        elsif @applicant.status==5 #PROPEDEUTICO
          text = "Por este conducto me es grato notificarle que ha sido aceptado como alumno al curso propedeutico de <b>#{@programa}</b> para el ciclo <b>#{@ciclo}</b>, que inicia el próximo <b>#{@fecha_inicio}</b> y concluye el <b>#{@fecha_fin}</b>. Le informo que las fechas establecidas para la  inscripción son el próximo <b>#{@fecha_inscripcion}</b>.\n\n"
          
          text = text + "Así mismo le informo que los cursos propedéuticos son aquellos destinados a preparar a los estudiantes aspirantes para ingresar a un Programa de Maestría. El objetivo de estos cursos será uniformar y nivelar  los conocimientos de los aspirantes a un Programa. Estos cursos podrán servir como evaluación para la admisión al Programa correspondiente, siempre y cuando se aprueben todas las materias con calificación mínima de 80 puntos. En caso de reprobar el curso propedéutico, los estudiantes podrán realizar por segunda ocasión el examen de admisión. Sin embargo, el curso propedéutico se podrá cursar sólo por una ocasión.\n\n"
          
          text = text + "Le envío una felicitación por este logro académico. Para cualquier duda o comentario al respecto, estoy a sus órdenes."
         
        elsif @applicant.status==2 # RECHAZADO
          text = "Por medio del presente me permito informar a usted que el Comité de Estudios de Posgrado en su reunión del pasado <b>#{@fecha_revision}</b> ha decidido el ingreso de aspirantes a los programas académicos de este Centro. Después de ser analizada su solicitud se ha determinado no aceptarlo.\n\n"
          text = text + "El Comité de Ingreso le recomienda, de ser de su interés, realizar de nueva cuenta la solicitud en la próxima convocatoria y atender a las siguientes recomendaciones en su anteproyecto de investigación:\n\n"
          text = text + "\"#{@recomendacion}\"\n\n"
          text = text + "A sus órdenes para cualquier duda o comentario al respecto."
        end
      
       
        pdf.text text, :align=>:justify,:inline_format=>true
        pdf.text atentamente, :align=>:center, :inline_format=>true
       
        filename = "carta-aspirante-#{@applicant.id}.pdf"
      
        send_data pdf.render, filename: filename, type: "application/pdf", disposition: "inline"
      end #Prawn::Document
    end # if params[:type]
  end # def certificates

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
    certificate.type_id         = type
    certificate.save

    return "%03d" % maximum
  end
  
  def get_month_name(number)
    months = ["enero","febrero","marzo","abril","mayo","junio","julio","agosto","septiembre","octubre","noviembre","diciembre"]
    name = months[number - 1]
    return name
  end

  def applicant_logout
    session[:applicant_user] = nil
    session[:locale] = nil
    @message = "Out of session"
    @url = "/aspirantes/registro/datos"

    @config = User.where(:email=>'SYSTEM').first.config rescue nil
    @active = @config[:applicants][:documents_status] rescue nil
    render :template => "applicants/applicants_login",:layout=>false
  end
  
  def set_locale
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale
 
    if params[:locale]
      session[:locale]=params[:locale]
    end
  end

private
  def auth_indigest
    user = params[:user]
    password = params[:password]

    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"

    if user && password
      if Applicant.where(:status=>[7,8],:id=>user,:password=>password).size.eql? 1
        session[:applicant_user] = user
      else
        @user    = user
        @message = "Usuario o password incorrectos"
      end
    end

    if session_authenticated?
      if !params[:action].eql? "download_app_file" # exception to download the file itself
        if ApplicantFile.where(:applicant_id=>session[:applicant_user],:file_type=>12).size>0
          @name = Applicant.find(session[:applicant_user]).full_name rescue ""
          @include_js   = "applicants.register.js"
          @t = t(:applicants)
          render :template => "applicants/applicants_access",:layout=>'standalone'
        end
      end

      return true
    else
      @url = "/aspirantes/registro/datos"
      @config = User.where(:email=>'SYSTEM').first.config rescue nil
      @active = @config[:applicants][:documents_status] rescue nil
      render :template => "applicants/applicants_login",:layout=>false
    end
  end ##auth_digest

  def session_authenticated?
    session[:applicant_user] rescue nil
  end

end
