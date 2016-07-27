# coding: utf-8

require 'digest/md5'

class InternshipsController < ApplicationController
  load_and_authorize_resource
  respond_to :html, :xml, :json
  before_filter :auth_required, :except=>[:applicant_form,:applicant_create,:applicant_file,:files_register,:upload_file_register]
  before_filter :auth_indigest, :only=>[:files_register,:upload_file_register]

  def index
    @institutions = Institution.order('name').where("id IN (SELECT DISTINCT institution_id FROM internships)")
    @staffs = Staff.order('first_name').where("id IN (SELECT DISTINCT staff_id FROM internships)")
    @internship_types = InternshipType.order('name')

    if current_user.access == User::OPERATOR
      @campus = Campus.order('name').where(:id=> current_user.campus_id)
    else
      @campus = Campus.order('name')
    end
  end

  def live_search
    @aareas           = get_areas(current_user)
    if current_user.access == User::OPERATOR
      @internships = Internship.order("first_name").where(:campus_id => current_user.campus_id,:area_id=>@aareas)
    else
      @internships = Internship.order("first_name")
    end

    if params[:institution] != '0' then
      @internships = @internships.where(:institution_id => params[:institution])
    end

    if params[:staff] != '0' then
      @internships = @internships.where(:staff_id => params[:staff])
    end

    if params[:internship_type] != '0' then
      @internships = @internships.where(:internship_type_id => params[:internship_type])
    end

    if params[:campus] != '0' then
      @internships = @internships.where(:campus_id => params[:campus])
    end

    if !params[:q].blank?
      @internships = @internships.where("(CONCAT(first_name,' ',last_name) LIKE :n OR id LIKE :n)", {:n => "%#{params[:q]}%"})
    end

    s = []

    if !params[:status_activos].blank?
      s << params[:status_activos].to_i
    end

    if !params[:status_finalizados].blank?
      s << params[:status_finalizados].to_i
    end

    if !params[:status_inactivos].blank?
      s << params[:status_inactivos].to_i
    end

    if !params[:status_solicitudes].blank?
      s << params[:status_solicitudes].to_i
    end

    if !s.empty?
      @internships = @internships.where("status IN (#{s.join(',')})")
    end

    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.xls do
        rows = Array.new
        @internships.collect do |s|
          rows << {'Nombre' => s.first_name,
                   'Apellidos' => s.last_name,
                   'Sexo' => s.gender,
                   'Email' => s.email,
                   'Fecha de Nacimiento' => s.date_of_birth,
                   'Tipo' => s.internship_type.name,
                   'Institucion' => (s.institution.name rescue ''),
                   'Inicio' => s.start_date,
                   'Fin' => s.end_date,
                   'Asesor' => (s.staff.full_name rescue ''),
                   'Tesis' => s.thesis_title,
                   'Actividades' => s.activities
                   }
        end
        column_order = ["Nombre", "Apellidos", "Sexo","Email", "Fecha de Nacimiento", "Tipo", "Institucion", "Inicio", "Fin", "Asesor", "Tesis", "Actividades"]
        to_excel(rows, column_order, "ServiciosCIMAV", "ServiciosCIMAV")
      end
    end

  end

  def show
    @internship   = Internship.find(params[:id])
    @countries    = Country.order('name')
    @institutions = Institution.order('name')
    @internship_types = InternshipType.order('name')

    @states  = State.order('code')
    @token   = Token.where(:attachable_id=>@internship.id,:attachable_type=>@internship.class.to_s)

    @applicant_log = ActivityLog.where(:user_id=>0).where("activity like '%:internship_id=>#{@internship.id}%'")

    @aareas           = get_areas(current_user)

    @operator = false
    if current_user.access == User::OPERATOR
      @campus   = Campus.order('name').where(:id=> current_user.campus_id)
      @areas    = Area.where(:id=> @aareas).order('name')
      @staffs   = Staff.where(:area_id=> @aareas).order('first_name').includes(:institution)
      @operator = true
    else
      @areas  = Area.order('name')
      @staffs = Staff.order('first_name').includes(:institution)
      @campus = Campus.order('name')
    end

    render :layout => false
  end

  def new
    @internship       = Internship.new
    @institutions     = Institution.order('name')
    @internship_types = InternshipType.order('name')
    @countries        = Country.order('name')
    @states           = State.order('name')

    @aareas           = get_areas(current_user)

    @operator = false
    if current_user.access == User::OPERATOR
      @campus   = Campus.order('name').where(:id=> current_user.campus_id)
      @areas    = Area.where(:id=> @aareas).order('name')
      @operator = true
    else
      @areas    = Area.order('name')
      @campus   = Campus.order('name')
    end
    render :layout => false
  end

  def create
    flash = {}
    @internship = Internship.new(params[:internship])

    if @internship.save
      flash[:notice] = "Servicio creado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Create Internship: #{@internship.id},#{@internship.first_name} #{@internship.last_name}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @internship.id
            render :json => json
          else
            redirect_to @internship
          end
        end
      end
    else
      flash[:error] = "Error al crear servicio."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @internship.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @internship
          end
        end
      end
    end
  end

  def update
    flash = {}
    @internship = Internship.find(params[:id])

    if @internship.update_attributes(params[:internship])
      flash[:notice] = "Servicio actualizado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Internship: #{@internship.id},#{@internship.first_name} #{@internship.last_name}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else
            redirect_to @internship
          end
        end
      end
    else
      flash[:error] = "Error al actualizar al becario."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @internship.errors
            json[:errors_full] = @internship.errors.full_messages
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @internship
          end
        end
      end
    end
  end

  def change_image
    @internship = Internship.find(params[:id])
    render :layout => 'standalone'
  end

  def upload_image
    flash = {}
    @internship = Internship.find(params[:id])
    if @internship.update_attributes(params[:internship])
      flash[:notice] = "Imagen actualizada."
    else
      flash[:error] = "Error al actualizar la imagen."
    end

    redirect_to :action => 'change_image', :id => params[:id]
  end

  def files
    @internship = Internship.includes(:internship_file).find(params[:id])
    @internship_file = InternshipFile.new
    render :layout => 'standalone'
  end

  def files_register
    @t    = t(:internships)
    @user = Internship.find(session[:internship_user])

    @req_docs   = InternshipFile::REQUESTED_DOCUMENTS.clone
    @include_js = "internships.register.files.js"
    @register   = true

    @req_docs.delete(1)

    @internship       = Internship.find(session[:internship_user])
    @internship_files = InternshipFile.where(:internship_id=>session[:internship_user])
    render :layout=> "standalone"
  end#def files_register
  
  def upload_applicant_file
    json = {}
    f = params[:internship_file]['file']

    @internship_file = InternshipFile.new
    @internship_file.internship_id = params[:internship_id]
    @internship_file.file_type = params[:file_type]
    @internship_file.file = f
    @internship_file.description = f.original_filename

    if @internship_file.save
      render :inline => "<status>1</status><reference>upload</reference><id>#{@internship_file.id}</id>"
    else
      render :inline => "<status>0</status><reference>upload</reference><errors>#{@internship_file.errors.full_messages}</errors>"
    end 
  rescue  
    render :inline => "<status>0</status><reference>upload</reference><errors>Error general</errors>"
  end

  def upload_file
    flash = {}
    params[:internship_file]['file'].each do |f|
      @internship_file               = InternshipFile.new
      @internship_file.internship_id = params[:internship_file]['internship_id']
      @internship_file.file_type     = params[:internship_file]['file_type']
      @internship_file.file          = f
      @internship_file.description   = f.original_filename

      if @internship_file.save
        flash[:notice] = "Archivo subido exitosamente."
      else
        flash[:error] = "Error al subir archivo."
      end
    end

    redirect_to :action => 'files', :id => params[:id]
  end

  def file
    s = Internship.find(params[:id])
    sf = s.internship_file.find(params[:file_id]).file
    send_file sf.to_s, :x_sendfile=>true
  end

  def delete_file
  end

  def applicant_files
    @req_docs = InternshipFile::REQUESTED_DOCUMENTS.clone
    @req_docs.delete(1)
 
    @internship = Internship.find(params[:id])
    @internship_files = InternshipFile.where(:internship_id=>params[:id],:file_type=>[2,3,4,5])
    render :layout=> "standalone"
  rescue ActiveRecord::RecordNotFound
    @error = 1
    render :template=>"internships/errors",:layout=> "standalone"
  end

  def id_card
    @internship = Internship.find(params[:id])
    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.pdf do
        @is_pdf = true
        html = render_to_string(:layout => false , :action => "id_card.html.haml")
        kit = PDFKit.new(html, :page_size => 'Legal', :orientation => 'Landscape', :margin_top    => '0',:margin_right  => '0', :margin_bottom => '0', :margin_left   => '0')
        kit.stylesheets << "#{Rails.root}/public/card.css"
        filename = "INTERN-#{@internship.id}.pdf"
        send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        return # to avoid double render call
      end
    end
  end

  def certificates
    @internship = Internship.find(params[:id])
    time = Time.new
    year = time.year.to_s
    dir  = t(:directory)

    if current_user.campus_id == 2
      title = dir[:academic_coordinator_monterrey][:title]
      name  = dir[:academic_coordinator_monterrey][:name]
      job   = dir[:academic_coordinator_monterrey][:job]
      @firma  = "#{title} #{name}"
      @puesto = "#{job}"
    else
      title = dir[:posgrado_chief][:title]
      name  = dir[:posgrado_chief][:name]
      job   = dir[:posgrado_chief][:job]
      @firma  = "#{title} #{name}"
      @puesto = "#{job}"
    end

    if params[:type] == "aceptacion"
      @consecutivo = get_consecutive(@internship, time, Certificate::ACCEPTANCE)
      @rails_root  = "#{Rails.root}"
      @year_s      = year[2,4]
      @year        = year
      @days        = time.day.to_s
      @month       = get_month_name(time.month)
      @nombre      = @internship.full_name
      @institucion = @internship.institution.name
      @carrera     = @internship.career
      @numero      = @internship.control_number
      @internado   = @internship.internship_type.name
      @departamento= @internship.office
      @asesor      = @internship.staff.full_name
      @horas       = @internship.total_hours.to_s
      @start_day   = @internship.start_date.day.to_s
      @start_month = get_month_name(@internship.start_date.month)
      @start_year  = @internship.start_date.year.to_s
      @end_day     = @internship.end_date.day.to_s
      @end_month   = get_month_name(@internship.end_date.month)
      @end_year    = @internship.end_date.year.to_s
      @horario     = @internship.schedule
      @proyecto    = @internship.thesis_title
      ######################################################################
      if ( @year.to_i == @start_year.to_i ) && ( @year.to_i == @end_year.to_i )
        @selector = 1
      end

      if @internship.gender == 'F'
        @genero  = "a"
        @genero2 = "la"
      elsif @internship.gender == 'H'
        @genero  = "o"
        @genero2 = "el"
      else
        @genero  = "x"
        @genero2 = "x"
      end

      html = render_to_string(:layout => 'certificate' , :template=> 'internships/certificates/constancia_aceptacion')
      kit = PDFKit.new(html, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
      filename = "carta-aceptacion-#{@internship.id}.pdf"
      send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
      return
    end

    if params[:type] == "liberacion"
      @consecutivo = get_consecutive(@internship, time, Certificate::RELEASE)
      @rails_root  = "#{Rails.root}"
      @year_s      = year[2,4]
      @year        = year
      @days        = time.day.to_s
      @month       = get_month_name(time.month)
      @nombre      = @internship.full_name
      @institucion = @internship.institution.name
      @carrera     = @internship.career
      @numero      = @internship.control_number
      @internado   = @internship.activities
      @departamento= @internship.office
      @asesor      = @internship.staff.full_name
      @puntuacion  = @internship.grade
      @horas       = @internship.total_hours.to_s
      @start_day   = @internship.start_date.day.to_s
      @start_month = get_month_name(@internship.start_date.month)
      @start_year  = @internship.start_date.year.to_s
      @end_day     = @internship.end_date.day.to_s
      @end_month   = get_month_name(@internship.end_date.month)
      @end_year    = @internship.end_date.year.to_s
      @horario     = @internship.schedule
      @proyecto    = @internship.thesis_title
      @internship_type = @internship.internship_type.name
      ######################################################################
      if @internship.gender == 'F'
        @genero  = "a"
        @genero2 = "la"
      elsif @internship.gender == 'H'
        @genero  = "o"
        @genero2 = "el"
      else
        @genero  = "x"
        @genero2 = "x"
      end

      html = render_to_string(:layout => 'certificate' , :template=> 'internships/certificates/constancia_liberacion')
      kit = PDFKit.new(html, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
      filename = "carta-liberacion-#{@internship.id}.pdf"
      send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
      return
    end

    if params[:type] == "uso"
      @consecutivo = get_consecutive(@internship, time, Certificate::USE)
      @rails_root  = "#{Rails.root}"
      @year_s      = year[2,4]
      @year        = year
      @days        = time.day.to_s
      @month       = get_month_name(time.month)
      @nombre      = @internship.full_name
      @institucion = @internship.institution.name
      @carrera     = @internship.career
      @numero      = @internship.control_number
      @internado   = @internship.internship_type.name
      @departamento= @internship.office
      @asesor      = @internship.staff.full_name
      @horas       = @internship.total_hours.to_s
      @start_day   = @internship.start_date.day.to_s
      @start_month = get_month_name(@internship.start_date.month)
      @start_year  = @internship.start_date.year.to_s
      @end_day     = @internship.end_date.day.to_s
      @end_month   = get_month_name(@internship.end_date.month)
      @end_year    = @internship.end_date.year.to_s
      @horario     = @internship.schedule
      @proyecto    = @internship.thesis_title
      ######################################################################
      if @internship.gender == 'F'
        @genero  = "a"
        @genero2 = "la"
      elsif @internship.gender == 'H'
        @genero  = "o"
        @genero2 = "el"
      else
        @genero  = "x"
        @genero2 = "x"
      end

      html = render_to_string(:layout => 'certificate' , :template=> 'internships/certificates/constancia_uso_informacion')
      kit = PDFKit.new(html, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
      filename = "carta-uso-informacion-#{@internship.id}.pdf"
      send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
      return
    end
  end

  def applicant_form
    @option           = params[:option]
    @internship       = Internship.new
    @institutions     = Institution.order('name')
    @internship_types = InternshipType.order('name')
    @countries        = Country.order('name')

    @states           = State.order('name')

    if @option.eql? "monterrey"
      @areas  = Area.where("id not in (1,2) and id=14") 
    else    
      @areas  = Area.where("id not in (1,2)").order('name') 
    end
    render :layout => 'standalone'
  end

  def applicant_create
    flash = {}
    @internship = Internship.new(params[:internship])
    @internship.status=3
    if @internship.area_id.eql? 14
      @internship.campus_id = 2 #Monterrey
    else
      @internship.campus_id = 1 #Default Chihuahua
    end
    @internship.applicant_status=0

    if params[:internship][:institution_id].to_i.eql? 0
      @internship.institution_id=2
      @internship.notes = "#{@internship.notes} \ninstitucion sugerida: #{params[:text_institution_id]}"
    end

    if params[:internship][:internship_type_id].to_i.eql? 0
      @internship.notes = "#{@internship.notes} \nservicio sugerido: #{params[:text_internship_type_id]}"
    end

    if @internship.save
      flash[:notice] = "Servicio creado para applicant."

      ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{@internship.id},:activity=>'El usuario hace una solicitud por internet'}"}).save
      @uri = generate_applicant_document(@internship)
      send_mail(@internship,@uri,1,nil)
      send_mail(@internship,@uri,2,nil)

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq]  = @internship.id
            json[:uri]   = @uri
            render :json => json
          else
            redirect_to @internship
          end
        end
      end
    else
      flash[:error] = "Error al crear servicio para applicant."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @internship.errors
            logger.info "################## #{@internship.errors.full_messages}"
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @internship
          end
        end
      end
    end
  end#applicant_create

  def applicant_file
    @internship = Internship.find(params[:id])
    @token      = params[:token]

    t = Token.where(:token=>@token,:attachable_id=>@internship.id)

    @r_root  = Rails.root.to_s
    filename = "#{@r_root}/private/files/internships/#{@internship.id}/registro.pdf"
    send_file filename, :x_sendfile=>true
  end#applicant_file
  
  def upload_file_register
    json = {}
    f = params[:internship_file]['file']

    @internship_file = InternshipFile.new
    @internship_file.internship_id = session[:internship_user].to_i
    @internship_file.file_type = params[:file_type]
    @internship_file.file = f
    @internship_file.description = f.original_filename

    if @internship_file.save
      render :inline => "<status>1</status><reference>upload</reference><id>#{@internship_file.id}</id>"
    else
      render :inline => "<status>0</status><reference>upload</reference><errors>#{@internship_file.errors.full_messages}</errors>"
    end 
 # rescue  
 #   render :inline => "<status>0</status><reference>upload</reference><errors>Error general</errors>"
  end

  def applicant_interview
    @internship = Internship.find(params[:id])
    @staff      = Staff.find(params[:staff_id])
    @user       = get_user(@internship.area_id)
    @date       = params[:date]
    @text       = params[:text]
    @adate      = @date.split("-")
    @ahour      = @adate[3].split(":")
    @hour       = "#{@ahour[0].to_s.rjust(2,"0")}:#{@ahour[1].to_s.rjust(2,"0")}"

    ## mail al entrevistado
    @text       = "La entrevista se ha programado para el día #{@adate[0]} de #{get_month_name(@adate[1].to_i)} de #{@adate[2]} a las #{@hour} horas, deberá presentarse con #{@staff.full_name}. #{@text}"
    send_mail(@internship,"",3,@text)

    ## mail al entrevistador

    ## generando token para aprobar servicio
    token                   = Token.new
    token.attachable_id     = @internship.id
    token.attachable_type   = @internship.class.to_s
    token.token             = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
    token.status            = 1
    token.expires           = Date.today + 40
    token.save
    
    @text = "Se ha programado la cita para entrevista de servicio social con #{@internship.full_name} [#{@internship.email}] para el día #{@adate[0]} de #{get_month_name(@adate[1].to_i)} de #{@adate[2]} a las #{@hour} horas."


    @content= "{:email=>'#{@internship.email}',:view=>22,:reply_to=>'#{@user.email}',:text=>'#{@text}',:token=>'#{token.token}'}"
    # @staff.email
    send_simple_mail(@staff.email,"Se ha programado un horario para entrevista de servicio social ",@content)
    ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{@internship.id},:activity=>'Se manda un correo con el horario a #{@staff.full_name} - #{@staff.email}'}"}).save

    @internship.applicant_status = 4 ## estatus de entrevista
    @internship.save

    json = {}
    json[:status]= 1
    render :json=> json
  end#applicant_interview
  
  def applicant_interview_qualify
    @save  = false
    @token = params[:token]
    @t = Token.where(:token=>@token,:status=>1,:attachable_type=>'Internship').where("expires>=?",Date.today).limit(1)

    if @t.size>0
      @internship = Internship.find(@t[0].attachable_id)
      if params[:auth]
        @save  = true
        @t[0].status =2  # Token class
        if params[:auth].to_i.eql? 1
          @internship.applicant_status = 3
        elsif params[:auth].to_i.eql? 2
          @internship.applicant_status = 2
        end
        @internship.save
        @t[0].save
      end
    else
      render file: "#{Rails.root}/public/404.html", layout: false, status: 404
      return
    end

    render :layout => false
  end

  def generate_applicant_document(i) #i for internship
    @genero = ""
    if i.gender.eql? "H"
      @genero = "Masculino"
    elsif i.gender.eql? "F"
      @genero = "Femenino"
    end

    @db          = i.date_of_birth
    @birth       = "#{@db.day} de #{get_month_name(@db.month)} de #{@db.year}"
    @bp          = Country.find(i.country_id).name rescue "" #born_place
    @institution = Institution.find(i.institution_id).name rescue ""
    @email       = i.email
    @i_type      = InternshipType.find(i.internship_type_id).name rescue ""
    @phone       = i.phone
    @smedico     = i.health_insurance
    @nsmedico    = i.health_insurance_number
    @contacto    = i.accident_contact

    @r_root  = Rails.root.to_s
    filename = "private/files/internships/#{i.id}"
    FileUtils.mkdir_p(filename) unless File.directory?(filename)
    template = "#{@r_root}/private/prawn_templates/form_reg_estudiantes_externos.png"
    pdf = Prawn::Document.new(:background => template, :background_scale=>0.36, :right_margin=>20)
    pdf.draw_text i.full_name,  :at=>[60,567], :size=>10
    pdf.draw_text @genero,      :at=>[49,554], :size=>10
    pdf.draw_text @birth,       :at=>[117,541], :size=>10
    pdf.draw_text @bp,          :at=>[115,527], :size=>10
    pdf.draw_text @institution, :at=>[142,514], :size=>10
    pdf.draw_text @i_type,      :at=>[181,501], :size=>10
    pdf.draw_text @phone,       :at=>[60,488], :size=>10
    pdf.draw_text @email,       :at=>[105,475], :size=>10
    pdf.draw_text @smedico,     :at=>[175,462], :size=>10
    pdf.draw_text @nsmedico,    :at=>[152,448], :size=>10
    pdf.draw_text @contacto,    :at=>[160,435], :size=>10
    pdf.render_file "#{filename}/registro.pdf"

    token = Token.new
    token.attachable_id     = i.id
    token.attachable_type   = i.class.to_s
    token.token             = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
    token.status            = 1
    token.expires           = Date.today + 30
    token.save

    return "/internados/aspirante/#{i.id}/formato/#{token.token}"
    #send_data pdf.render, type: "application/pdf", disposition: "inline"
  end

  def send_simple_mail(to,subject,content)
    email         = Email.new
    email.from    ="atencion.posgrado@cimav.edu.mx"
    email.to      = to
    email.subject = subject
    email.content = content
    email.status  = 0
    email.save

    #SystemMailer.notification_email(email).deliver
  end


  def send_mail(i,uri,opc,text)
    user    = get_user(i.area_id)
    
    if opc.eql? 1
      ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se intenta mandar un correo al solicitante'}"}).save
    elsif opc.eql? 2
      ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se intenta mandar un correo al asistente'}"}).save
    elsif opc.eql? 3
      ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se intenta mandar un correo de fecha de entrevista'}"}).save
    end

    if opc.eql? 1
      @u_email   = i.email
      subject = "Solicitud Servicio Social CIMAV"
      content = "{:full_name=>'#{i.full_name}',:email=>'#{i.email}',:view=>13,:reply_to=>'#{user.email}',:uri=>'#{uri}'}"
    elsif opc.eql? 2
      @u_email   = user.email
      subject = "Se ha realizado una Solicitud Servicio Social CIMAV"
      content = "{:full_name=>'#{i.full_name}',:email=>'#{i.email}',:view=>14,:reply_to=>'#{i.email}',:uri=>'#{uri}'}"
    elsif opc.eql? 3
      @u_email   = i.email
      subject = "Se ha programado fecha para entrevista Solicitud Servicio Social CIMAV"
      content = "{:full_name=>'#{i.full_name}',:email=>'#{i.email}',:view=>15,:reply_to=>'#{user.email}',:text=>'#{text}'}"
    end

    email         = Email.new
    email.from    ="atencion.posgrado@cimav.edu.mx"
    email.to      = @u_email
    email.subject = subject
    email.content = content
    email.status  = 0
    email.save

    if opc.eql? 1
      ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se manda un correo al solicitante'}"}).save
    elsif opc.eql? 2
      ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se manda un correo al asistente'}"}).save
    elsif opc.eql? 3
      ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'El usuario programa fecha de entrevista'}"}).save
    end
  end#send_mail

  def get_user(area_id)
     users = User.where("areas like '%\"#{area_id}\"%'")
     return users[0]
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
  
  def applicant_logout
    session[:internship_user] = nil
    session[:locale] = nil
    @message = "Out of session"
    @url = "/internados/aspirantes/documentos"
    render :template => "internships/applicants_login",:layout=>false
  end

private
  def auth_indigest
    user = params[:user]
    password = params[:password]

    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"

    if user && password
      if Internship.where(:status=>3,:applicant_status=>3,:id=>user,:password=>password).size.eql? 1
        session[:internship_user] = user
      else
        @user    = user
        @message = "Usuario o password incorrectos"
      end
    end

    if session_authenticated?
      return true
    else
      @url = "/internados/aspirantes/documentos"
      render :template => "internships/applicants_login",:layout=>false
    end
  end ## auth_indigest

  def session_authenticated?
    session[:internship_user] rescue nil
  end
  
end
