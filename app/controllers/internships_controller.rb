# coding: utf-8

require 'digest/md5'
require 'open-uri'
require 'json'

class InternshipsController < ApplicationController
  #load_and_authorize_resource
  respond_to :html, :xml, :json
  before_filter :auth_required, :except=>[:upload_image,:change_image,:applicant_form,:applicant_create,:applicant_file,:upload_file_register,:finalize,:applicant_logout,:applicant_interview_qualify,:summer,:finalize_summer,:files_register,:finalize]
  before_filter :auth_indigest, :only=>[:finalize,:files_register]

  def index
    @institutions     = Institution.order('name').where("id IN (SELECT DISTINCT institution_id FROM internships)")
    @staffs           = Staff.order('first_name').where("id IN (SELECT DISTINCT staff_id FROM internships)")
    campuses          = current_user.campus_id
    @internship_types = InternshipType.order('name')
    min               = Internship.minimum(:created_at)
    max               = Internship.maximum(:created_at)
    @years            = (min.year..max.year).to_a

    if current_user.access == User::OPERATOR
      if campuses.eql? 0
        @campus = Campus.order('name')
      else
        @campus = Campus.order('name').where(:id=> current_user.campus_id)
      end

      @aareas       = get_areas(current_user)
      @areas  = Area.where(:id=>@aareas)
    else
      @campus = Campus.order('name')
      @areas  = Area.all 
    end
  end

  def live_search
   limit       = 10000
   @aareas     = get_areas(current_user)
   
   campuses = current_user.campus_id
   
   extra_where = "(applicant_status<>99 OR applicant_status is NULL)"
   order       = "first_name" ## valor default de ordenacion, no debe estar nulo o vacio
   where_hash  = Hash.new
   
   if @aareas.size>0
    where_hash[:area_id]= @aareas
   end
   
   if campuses.size>0
     where_hash[:campus_id=> campuses]
   end #campuses
   
   if !params[:status_order].blank?
     order = "created_at desc"
   end
   
   
    if params[:area_s] != '0' then
      where_hash[:area_id] = params[:area_s]
    end

    if params[:institution] != '0' then
      where_hash[:institution_id] = params[:institution]
    end

    if params[:staff] != '0' then
      where_hash[:staff_id] = params[:staff]
    end

    if params[:internship_type] != '0' then
      where_hash[:internship_type_id] = params[:internship_type]
    end

    if params[:campus] != '0' then
      where_hash[:campus_id] = params[:campus]
    end
     
    if !params[:q].blank?
      extra_where << " AND (CONCAT(first_name,' ',last_name) LIKE '%#{params[:q]}%' OR id LIKE '%#{params[:q]}%')"
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
     
    if params[:year].to_i !=0
      if params[:year].to_i == 1
        max = Internship.maximum(:created_at)
        extra_where << "AND YEAR(created_at) in (#{max.year},#{max.year-1})"
      else
        extra_where << "AND YEAR(created_at)=#{params[:year]}"
      end
     
      
    end
     
   if !s.empty?
      where_hash[:status]= s
   end
     
   if !extra_where.empty? && !where_hash.empty?
     @internships = Internship.where(where_hash).where(extra_where).order(order).limit(limit)
   elsif !extra_where.empty? && where_hash.empty?
     @internships = Internship.where(extra_where).order(order).limit(limit)
   elsif extra_where.empty? && !where_hash.empty?
     @internships = Internship.where(where_hash).order(order).limit(limit)
   else
     @internships = Internship.order(order).limit(limit)
   end  
   
   
   respond_with do |format|
     format.html do
       render :layout => false
     end #format.html
     format.xls do
        rows = Array.new

        @internships.collect do |s|
          rows << {'Nombre' => s.first_name,
                   'Apellidos' => s.last_name,
                   'Sexo' => s.gender,
                   'Email' => s.email,
                   'Fecha de Nacimiento' => s.date_of_birth,
                   'Tipo' => (s.internship_type.name rescue 'N.D'),
                   'Institucion' => (s.institution.name rescue ''),
                   'Inicio' => s.start_date,
                   'Fin' => s.end_date,
                   'Asesor' => (s.staff.full_name rescue ''),
                   'Tesis' => s.thesis_title,
                   'Actividades' => s.activities,
                   'Fecha registro' => (s.created_at.to_date.strftime("%Y.%m.%d") rescue '')
                   }
        end
        column_order = ["Nombre", "Apellidos", "Sexo","Email", "Fecha de Nacimiento", "Tipo", "Institucion", "Inicio", "Fin", "Asesor", "Tesis", "Actividades","Fecha registro"]
        to_excel(rows, column_order, "ServiciosCIMAV", "ServiciosCIMAV")
      end #format.xls
   end #respond_with

  end#live_search
 

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
      @staffs   = Staff.includes(:institution).where(:area_id=> @aareas).where(:status=>0).order(:first_name)
      @operator = true
    else
      @areas  = Area.order('name')
      @staffs = Staff.includes(:institution).order('first_name').where(:status=>0).order(:first_name)
      @campus = Campus.order('name')
    end

    logger.info "###################### AQUI 1 #{@internship.staff_id}"
    if !@internship.staff_id.nil?
      s = Staff.find(@internship.staff_id)
      logger.info "#################### AQUI 2 #{s.id} #{s.status} #{s.class}"
      if s.status.to_i.eql? 1
        logger.info "################## AQUI 3 #{s.class}"
        @staffs << s
      end
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
    @internship.origin = 1

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

    @req_docs.keep_if {|a| a.in? [2,3,4,5,6]}

    @internship       = Internship.find(session[:internship_user])
    @internship_files = InternshipFile.where(:internship_id=>session[:internship_user])

    @i_file = InternshipFile.where(:internship_id=>session[:internship_user].to_i,:file_type=>6)
 
   if @i_file.size.eql? 0
    security_course(@internship.email)
   end

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
   
    @internship = Internship.find(params[:id])
   
    if @internship.internship_type_id.eql? 8 #Verano CIMAV
      @req_docs.keep_if {|a| a.in? [4,7,8,9,10]}  
    else
      @req_docs.keep_if {|a| a.in? [2,3,4,5,6]}
    end

    @internship_files = InternshipFile.where(:internship_id=>params[:id],:file_type=>[2,3,4,5,6,7,8,9,10])
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
    @sign        = params[:sign_id]
    background = "#{Rails.root.to_s}/private/prawn_templates/membretada.png"


    time = Time.new
    year = time.year.to_s
    dir  = t(:directory)

    if @sign.eql? "1"
      title    = dir[:academic_director][:title]
      name     = dir[:academic_director][:name]
      job      = dir[:academic_director][:job]
      @sgender = dir[:academic_director][:gender]
      @firma   = "#{title} #{name}"
      @puesto  = "#{job}"
    elsif @sign.eql? "2"
      title    = dir[:posgrado_chief][:title]
      name     = dir[:posgrado_chief][:name]
      job      = dir[:posgrado_chief][:job]
      @sgender = dir[:posgrado_chief][:gender]
      @firma   = "#{title} #{name}"
      @puesto  = "#{job}"
    elsif @sign.eql? "3"
      title    = dir[:scholar_control][:title]
      name     = dir[:scholar_control][:name]
      job      = dir[:scholar_control][:job]
      @sgender = dir[:scholar_control][:gender]
      @firma   = "#{title} #{name}"
      @puesto  = "#{job}"
    elsif @sign.eql? "4"
      title    = dir[:academic_coordinator_monterrey][:title]
      name     = dir[:academic_coordinator_monterrey][:name]
      job      = dir[:academic_coordinator_monterrey][:job]
      @sgender = dir[:academic_coordinator_monterrey][:gender]
      @firma   = "#{title} #{name}"
      @puesto  = "#{job}"
    elsif @sign.eql? "5"
      title    = dir[:academic_coordinator_durango][:title]
      name     = dir[:academic_coordinator_durango][:name]
      job      = dir[:academic_coordinator_durango][:job]
      @sgender = dir[:academic_coordinator_durango][:gender]
      @firma   = "#{title} #{name}"
      @puesto  = "#{job}"
    elsif @sign.eql? "6"
      @area = Area.find(@internship.area_id)
      @firma   = "#{@area.leader}"
      @puesto  = "#{@area.name}"
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
      @asesor      = @internship.staff.full_name rescue '[IMPORTANTE] ASESOR AUN NO HA SIDO ASIGNADO'
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


      Prawn::Document.new(:background => background, :background_scale=>0.36, :margin=>60 ) do |pdf|
        pdf.font_families.update(
            "Montserrat" => { :bold        => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Bold.ttf"),
                              :italic      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Italic.ttf"),
                              :bold_italic => Rails.root.join("app/assets/fonts/montserrat/Montserrat-BoldItalic.ttf"),
                              :normal      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Regular.ttf") })
        pdf.font "Montserrat"
        pdf.font_size 11
        x = 20
        y = 565 #664
        w = 300
        h = 50



        pdf.text_box "Coordinación de estudios de Posgrado\nNo° de Oficio  PO - #{@consecutivo}/#{@year}\n Chihuahua, Chih, a #{@days} de #{@month} de #{@year}.", :inline_format=>true, :at=>[x,y], :align=>:right ,:valign=>:top, :height=>h

        x = 20
        y -= 70
        w = 300
        pdf.font_size 12

        @a_quien_corr = "A quien corresponda \n\n <b>Presente.-</b>"

        pdf.text_box @a_quien_corr, :at=>[x, y], :align=>:justify, :valign=>:top, :inline_format=>true

        x = 20
        y -= 60
        w = 300

        @parrafo1 = "Por medio de la presente hago constar que #{@genero2} alumn#{@genero} <b>#{@nombre}</b>, perteneciente a <b>#{@institucion}</b>, de la carrera de <b>#{@carrera}</b> y con No. de control <b>#{@numero}</b> está aceptad#{@genero} en este Centro de Investigación para realizar <b>#{@internado}</b>, en el departamento de <b>#{@departamento}</b>, bajo la supervisión de <b>#{@asesor}</b>, cubriendo un total de <b>#{@horas}</b> Hrs., dentro del periodo comprendido del <b>#{@start_day} de #{@start_month} del #{@start_year} al #{@end_day} de #{@end_month} del #{@end_year}</b> del presente año en el siguiente horario de <b>#{@horario}</b>, en este Centro de Investigación, desarrollando el siguiente proyecto: "

        pdf.text_box @parrafo1, :at=>[x, y], :align=>:justify, :valign=>:top, :inline_format=>true

        x= 40
        y -= 150

        pdf.text_box "<b>#{@proyecto}</b>", :at=>[x,y], :align=>:justify,:valign=>:top,:inline_format=>true

        @parrafo2 = "Se extiende la presente constancia en la ciudad de Chihuahua, Chihuahua el dia #{@days} del mes de #{@month} de #{@year}, para los fines legales a que haya lugar."
        y -= 40
        x = 20
        pdf.text_box @parrafo2, :at=>[x,y], :align=>:justify,:valign=>:top,:inline_format=>true

        y = y - 100 #202
        h = 155
        x = 98

        @atentamente = "\n<b>A t e n t a m e n t e\n\n\n\n#{@firma}\n#{@puesto}</b>"
        pdf.text_box @atentamente, :at=>[x,y], :align=>:center,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
        filename = "carta-aceptacion-#{@internship.id}.pdf"

        send_data(pdf.render, :filename => filename, :type => 'application/pdf', disposition:'inline')

      end
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
      @asesor      = @internship.staff.full_name rescue '[IMPORTANTE] ASESOR AUN NO HA SIDO ASIGNADO'
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

      Prawn::Document.new(:background => background, :background_scale=>0.36, :margin=>60 ) do |pdf|
        pdf.font_families.update(
            "Montserrat" => { :bold        => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Bold.ttf"),
                              :italic      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Italic.ttf"),
                              :bold_italic => Rails.root.join("app/assets/fonts/montserrat/Montserrat-BoldItalic.ttf"),
                              :normal      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Regular.ttf") })
        pdf.font "Montserrat"
        pdf.font_size 11

        pdf.text "\n\n\n\n\n\nCoordinación de estudios de Posgrado\nNo° de Oficio  PO - #{@consecutivo}/#{@year}\n Chihuahua, Chih, a #{@days} de #{@month} de #{@year}.", :inline_format=>true, :align=>:right ,:valign=>:top

        pdf.font_size 12

        correspondencia = "\n\nA quien corresponda \n <b>Presente.-</b>"
        pdf.text correspondencia, :align=>:justify, :valign=>:top, :inline_format=>true

        parrafo1 = "\n\nPor medio de la presente hago constar que el alumno <b>#{@nombre}</b>, de la carrera de <b>#{@carrera}</b> perteneciente a <b>#{@institucion}</b> y con número de control <b>#{@numero}</b> realizó <b>#{@internship_type}</b>, dentro del periodo comprendido del <b>#{@start_day} de #{@start_month} de #{@start_year} al #{@end_day} de #{@end_month} de #{@end_year}</b> cubriendo un total de <b>#{@horas}</b> horas en este Centro de Investigación, desarrollando las siguientes actividades:"
        pdf.text parrafo1, :align=>:justify, :valign=>:top, :inline_format=>true

        pdf.font_size 11

        actividades = "\n<b>#{@internado}</b>"
        pdf.text actividades, :align=>:justify,:valign=>:top,:inline_format=>true

        pdf.font_size 12

        parrafo2 = "\nQue nos reporta con resultados muy satisfactorios el asesor <b>#{@asesor}</b>, una puntuación de <b>#{@puntuacion}</b>, por lo que no tenemos reserva alguna en felicitarlo por su excelente formación."
        pdf.text parrafo2, :align=>:justify,:valign=>:top,:inline_format=>true

        parrafo3 = "\nSe extiende la presente constancia en la ciudad de Chihuahua, Chihuahua el dia #{@days} del mes de #{@month} de #{@year}, para los fines legales a que haya lugar."
        pdf.text parrafo3, :align=>:justify,:valign=>:top,:inline_format=>true

        pdf.font_size 11

        atentamente = "\n<b>A t e n t a m e n t e\n\n\n\n#{@firma}\n#{@puesto}</b>"
        
        firma_asesor = "\n<b>Vo. Bo \n\n\n\n#{@asesor}\n Asesor Responsable</b>"

        pdf.text "\n"
        data  = [[atentamente,firma_asesor]]
        tabla = pdf.make_table(data, :width => 500, :cell_style => {:align=>:center,:size => 11, :padding => 0, :inline_format => true, :border_width => 0}, :position => :center, :column_widths => [250,250])
        tabla.draw
        
        filename = "carta-liberacion-#{@internship.id}.pdf"
        send_data(pdf.render, :filename => filename, :type => 'application/pdf', disposition:'inline')
      end
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
      @asesor      = @internship.staff.full_name rescue '[IMPORTANTE] ASESOR AUN NO HA SIDO ASIGNADO'
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
    if request.url.include? "verano"
      
      @summer= true
      @page_title  = 'Solicitud de Verano CIMAV'
      @page_note   = 'Una vez llena la solicitud de solicitará la carga de documentos'
      now          = Time.now
      limit        = Time.new(2019,4,10,23,59,59,"-06:00")
      @closed      = false
      @warning     = false
      
      diff = limit - now
     
      if diff < 0  ## cuando la diferencia devuelve números negativos es porque ya nos pasamos
        @warning    = true
        @closed     = true
        @page_note2 = "La convocatoria ha cerrado!"
      elsif diff <= (24*60*60)  ## advertencia con 1 dia de anticipacion, en segundos 24 horas*60 minutos*60 segundos
        @warning = true
        @page_note2  = "La convocatoria cierra el día #{limit.day} de #{t(:date)[:month_names][limit.month]} de #{limit.year} a media noche hora de las montañas (GMT-6) donde son las #{now.strftime('%H')}:#{now.strftime('%M')} del #{now.day} de #{t(:date)[:month_names][now.month]} del #{now.year}."
      end
    else
      @summer= false
      @page_title = 'Solicitud de prácticas profesionales'
    end
    
    @include_js = "internships.js"
    @option           = params[:option]
    @internship       = Internship.new
    @institutions     = Institution.order('name')
    #@internship_types = InternshipType.where("id!=8").order('name')
    @internship_types = InternshipType.order('name')

    @countries        = Country.order('name')

    @states           = State.order('name')

    if @option.eql? "monterrey"
      @areas  = Area.where("id not in (1,2) and id=14") 
    else    
      @areas  = Area.where("id not in (1,2)").order('name') 
    end
    render :layout => 'bootstrap_layout'
  end

###########################################################################
  def applicant_create
    flash = {}
    @internship = Internship.new(params[:internship])
    @internship.status=3

    if @internship.area_id.eql? 14
      @internship.campus_id = 2 #Monterrey
    elsif @internship.area_id.eql? 15
      @internship.campus_id = 4 #Durango
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

      if @internship.internship_type_id.eql? 8  ## para Verano CIMAV
        ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{@internship.id},:activity=>'El usuario hace una solicitud de Verano CIMAV por internet'}"}).save
       
        @internship.applicant_status= 99; ## estatus de pendiente, faltan los documentos
        @internship.save
          
        token = Token.new
        token.attachable_id     = @internship.id
        token.attachable_type   = @internship.class.to_s
        token.token             = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
        token.status            = 1
        token.expires           = Date.today + 1
        token.save

        json = {}
        json[:flash] = flash
        json[:uniq]  = @internship.id
        json[:internship_type_id] = @internship.internship_type_id
        json[:uri]   = @uri
        json[:token] = token.token
        render :json => json
        return
      else
        ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{@internship.id},:activity=>'El usuario hace una solicitud por internet'}"}).save
        @uri = generate_applicant_document(@internship)
        send_mail(@internship,@uri,1,nil)
        send_mail(@internship,@uri,2,nil)
      end
      
      
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq]  = @internship.id
            json[:internship_type_id] = @internship.internship_type_id
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

###########################################################################
  def summer
    @t    = t(:internships)

    @req_docs   = InternshipFile::REQUESTED_DOCUMENTS.clone
    @include_js = "internships.register.files.js"
      
    @internship       = Internship.find(params[:id])
    where = {:attachable_id=>@internship.id,:attachable_type=>@internship.class,:token=>params[:token],:status=>1}
    token = Token.where(where).where("expires>=?",Date.today)
   
    if token.size<=0
      render file: "#{Rails.root}/public/404.html", layout: false, status: 404
      return
    end
     
    @internship_files = InternshipFile.where(:internship_id=>params[:id])
      
    @req_docs.keep_if {|a| a.in? [4,7,8,9,10]}

    render :layout => 'bootstrap_layout'
  end

###########################################################################
  def finalize_summer
      @internship = Internship.find(params[:id])
      @internship.applicant_status= 3; ## autorizado
      @internship.save
   
      @token = Token.where(:token=>params[:token])
   
      if @token.size>0
        @token[0].status = 2
        @token[0].save
       
        send_mail(@internship,'',7,'') ## correo al solicitante
        send_mail(@internship,'',8,'') ## correo al contacto posgrado
        
        
        json = {}
        json[:flash] = flash
        json[:uniq]  = @internship.id
        json[:internship_type_id] = @internship.internship_type_id
        json[:uri]   = @uri
        render :json => json
      else
        json = {}
        json[:flash] = flash
        json[:errors] = @internship.errors.full_messages
        logger.info "################## #{@internship.errors.full_messages}"
        render :json => json, :status => :unprocessable_entity
      end 
      
  end

###########################################################################

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
    @internship_file.internship_id = params[:internship_id] || session[:internship_user].to_i
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

  def finalize
    @t    = t(:internships)
    @access = true
    if session[:internship_user].to_i.eql? params[:id].to_i
      @internship = Internship.find(params[:id])
      if @internship.applicant_status.eql? 3
        @internship = Internship.find(params[:id])
        @internship.status=0
        @internship.applicant_status=0
        @internship.save
        send_mail(@internship,"",6,"")
      else
        @access = false
      end
    else
      @access = false
    end

    render :layout => 'standalone'
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
        @t[0].save

        if params[:auth].to_i.eql? 1  ## APROBADO
          @internship.applicant_status = 3

          @internship.start_date = params[:start_date]
          @internship.end_date   = params[:end_date]
          @internship.activities = params[:activity_area]
        
          @internship.password = SecureRandom.base64(12)
          @internship.save
          send_mail(@internship,"",5,"")
        elsif params[:auth].to_i.eql? 2 ## RECHAZADO
          @internship.applicant_status = 2
          @internship.save
          send_mail(@internship,"",4,"")
        end
      end
    else
      render file: "#{Rails.root}/public/404.html", layout: false, status: 404
      return
    end

    if @save.eql? false
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end

    render :layout => 'standalone'
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
    pdf.font_families.update(
        "Montserrat" => { :bold        => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Bold.ttf"),
                          :italic      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Italic.ttf"),
                          :bold_italic => Rails.root.join("app/assets/fonts/montserrat/Montserrat-BoldItalic.ttf"),
                          :normal      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Regular.ttf") })
    pdf.font "Montserrat"
    pdf.font_size 11
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
    if opc.in? [7,8] ## solo Verano CIMAV
      user    = User.find(15)  ## <- Marcos López, esto en un futuro debe quedar en configuraciones
    else
      user    = get_user(i.area_id)
    end
    
    if !user.nil?
      if opc.eql? 1
        ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se intenta mandar un correo al solicitante'}"}).save
      elsif opc.eql? 2 
        ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se intenta mandar un correo al asistente'}"}).save
      elsif opc.eql? 3
        ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se intenta mandar un correo de fecha de entrevista'}"}).save
      elsif opc.eql? 4
        ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se intenta mandar un correo de servicio social no autorizado'}"}).save
      elsif opc.eql? 5
        ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se intenta mandar un correo de servicio social autorizado'}"}).save
      elsif opc.eql? 7 # Verano CIMAV
        ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se manda correo al solicitante'}"}).save
      elsif opc.eql? 8 # Verano CIMAV
        ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'Se manda correo al contacto de Posgrado'}"}).save
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
      elsif opc.eql? 4
        @u_email   = i.email
        subject = "No se ha autorizado Solicitud de Servicio CIMAV"
        text    = "Se le informa que no se ha autorizado su solicitud de servicio CIMAV."
        content = "{:full_name=>'#{i.full_name}',:email=>'#{i.email}',:view=>23,:reply_to=>'#{user.email}',:text=>'#{text}'}"
      elsif opc.eql? 5
        @u_email = i.email
        subject  = "Se ha autorizado Solicitud de Servicio CIMAV"
        content  = "{:full_name=>'#{i.full_name}',:email=>'#{i.email}',:i_id=>'#{i.id}',:pass=>'#{i.password}',:view=>24,:reply_to=>'#{user.email}'}"
      elsif opc.eql? 6
        @u_email = Settings.interships_cards_email
        subject  = "Se ha registrado un alumno como Servicio CIMAV #{i.id}"
        content  = "{:full_name=>'#{i.full_name}',:email=>'#{i.email}',:view=>'25',:reply_to=>'#{user.email}'}"
      elsif opc.eql? 7 
        @u_email = i.email
        subject  = "Ha registrado una solicitud para el Verano CIMAV"
        content  = "{:full_name=>'#{i.full_name}',:email=>'#{i.email}',:view=>'26',:reply_to=>'#{user.email}'}"
      elsif opc.eql? 8
        @u_email = user.email
        subject  = "Alguien ha realizado una solicitud para el Verano CIMAV"
        content  = "{:full_name=>'#{i.full_name}',:email=>'#{i.email}',:view=>'27',:reply_to=>'#{i.email}'}"
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
      elsif opc.eql? 4 
        ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'El entrevistador rechaza solicitud'}"}).save
      elsif opc.eql? 5
        ActivityLog.new({:user_id=>0,:activity=>"{:internship_id=>#{i.id},:activity=>'El entrevistador autoriza solicitud'}"}).save
      end
    end
  end#send_mail

  def get_user(area_id)
     users = User.where("areas like '%\"#{area_id}\"%'")
     users.each do |u|
       if !u.config[:internships_email_send].nil?
         if u.config[:internships_email_send]==true
           return u
         end
       end
     end

     return nil
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
      #Se comenta la restricción de acceso según el status del aplicante
      #if Internship.where(:status=>3,:applicant_status=>3,:id=>user,:password=>password).size.eql? 1
      if Internship.where(:id=>user,:password=>password).size.eql? 1
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

  def analize(line)
    if @counter>0
      if line.include? @email
        @row << line
        @counter = @counter + 1 
      elsif line.include? "Quiz title"
        @row << line
        @counter = @counter + 1 
      elsif line.include? "Points awarded"
        @row << line
        @counter = @counter + 1 
      elsif line.include? "Total score"
        @row << line
        @counter = @counter + 1 
      elsif line.include? "Passing score"
        @row << line
        @counter = @counter + 1 
      elsif line.include? "User fails"
        @row << line
        @counter = @counter + 1 
      elsif line.include? "User passes"
        @row << line
        @counter = @counter + 1 
      else
        @counter = 0 
        @row.pop
      end
    end
  
    if @counter.eql? 7
      @counter_hash = @counter_hash + 1
  
      @hash["#{@counter_hash}"] = @row.clone
  
      @counter = 0
      @row.clear
    end
  
    if line.include? "User name"
      @row << line
      @counter = 1
    end
  end

 
  def security_course(email)
    @email   = email
    @hash    = Hash.new
    @row     = Array.new
    @counter = 0 
    @exam1   = false
    @exam2   = false
    @exam3   = false
    @counter_hash = 0 

    open("http://csh.cimav.edu.mx/resultados/resultados1.txt") {|f|
      f.each_line {|line|
        analize(line)
      }
    }
    
    if !(@hash.size.eql? 0)
      if @hash["#{@counter_hash}"][6].include? "User passes"
        @exam1 = true
      end
    end
    
    @hash.clear
    @counter_hash = 0
    
    open("http://csh.cimav.edu.mx/resultados/resultados2.txt") {|f|
      f.each_line {|line|
        analize(line)
      }
    }
    if !(@hash.size.eql? 0)
      if @hash["#{@counter_hash}"][6].include? "User passes"
        @exam2 = true
      end
    end
    
    @hash.clear
    @counter_hash = 0
    
    open("http://csh.cimav.edu.mx/resultados/resultados3.txt") {|f|
      f.each_line {|line|
        analize(line)
      }
    }
    
    if !(@hash.size.eql? 0)
      if @hash["#{@counter_hash}"][6].include? "User passes"
        @exam3 = true
      end
    end
    
    @hash.clear
    @counter_hash = 0
    
    logger.info @exam1
    logger.info @exam2
    logger.info @exam3
    
    if @exam1 && @exam2 && @exam3
      @i_file = InternshipFile.new
      @i_file.internship_id = session[:internship_user].to_i
      @i_file.description   = "Curso"
      @i_file.file          = "Curso"
      @i_file.file_type     = 6
      @i_file.save
    end
  end 
end
