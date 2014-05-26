# coding: utf-8
class InternshipsController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

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
    if current_user.access == User::OPERATOR
      @internships = Internship.order("first_name").where(:campus_id => current_user.campus_id)
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
    @internship = Internship.find(params[:id])
    @countries = Country.order('name')
    @institutions = Institution.order('name')
    @internship_types = InternshipType.order('name')
    @staffs = Staff.order('first_name').includes(:institution)
    @states = State.order('code')

    if current_user.access == User::OPERATOR
      @campus = Campus.order('name').where(:id=> current_user.campus_id)
    else
      @campus = Campus.order('name')
    end 

    render :layout => false
  end

  def new
    @internship = Internship.new
    @institutions = Institution.order('name')
    @internship_types = InternshipType.order('name')
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
      flash[:error] = "Error al crear becario."
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

  def upload_file
    flash = {}
    params[:internship_file]['file'].each do |f|
      @internship_file = InternshipFile.new
      @internship_file.internship_id = params[:internship_file]['internship_id']
      @internship_file.file = f
      @internship_file.description = f.original_filename
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
        kit.stylesheets << "#{Rails.root}#{Sapos::Application::ASSETS_PATH}card.css"
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
    if current_user.campus_id == 2
      @firma  = "Alejandra García García"
      @puesto = "Coordinador Académico Unidad Monterrey"
    else
      @firma  = "M.H. Nicté Ortiz Villanueva"
      @puesto = "Jefa del Departamento de Posgrado"
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
