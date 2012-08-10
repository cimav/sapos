# coding: utf-8
class StaffsController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
    @institutions = Institution.order('name')
  end

  def live_search
    @staffs = Staff.order("first_name")

    if params[:institution] != '0' then
      @staffs = @staffs.where(:institution_id => params[:institution])
    end 

    if !params[:q].blank?
      @staffs = @staffs.where("(CONCAT(first_name,' ',last_name) LIKE :n OR id LIKE :n)", {:n => "%#{params[:q]}%"}) 
    end

    s = []

    if !params[:status_activos].blank?
      s << params[:status_activos].to_i
    end

    if !params[:status_inactivos].blank?
      s << params[:status_inactivos].to_i
    end

    if !s.empty?
      @staffs = @staffs.where("status IN (#{s.join(',')})")
    end
        logger.debug "AQUI 2"

    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.xls do
        rows = Array.new
        @staffs.collect do |s|
          rows << {'Numero_Empleado' => s.employee_number,
                   'Nombre' => s.first_name,   
                   'Apellidos' => s.last_name,
                   'Correo_Elec' => s.email,
                   'Sexo' => s.gender,
                   'Fecha_Nac' => s.date_of_birth,
                   'CVU' => s.cvu,
                   'SNI' => s.sni,
                   'Estado' => s.status,
                 }
        end
        column_order = ["Numero_Empleado","Nombre","Apellidos","Correo_Elec","Sexo","Fecha_Nac","CVU","SNI","Estado"]
        to_excel(rows,column_order,"Docentes","Docentes")
      end 
    end
  end

  def show
    @staff = Staff.find(params[:id])
    @countries = Country.order('name')
    @institutions = Institution.order('name')
    @states = State.order('code')
    render :layout => false
  end

  def new
    @staff = Staff.new
    @institutions = Institution.order('name')
    render :layout => false
  end

  def create
    flash = {}
    @staff = Staff.new(params[:staff])

    if @staff.save
      flash[:notice] = "Docente creado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Create Staff: #{@staff.id},#{@staff.first_name} #{@staff.last_name}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @staff.id
            render :json => json
          else 
            redirect_to @staff
          end
        end
      end
    else
      flash[:error] = "Error al crear docente."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @staff.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @staff
          end
        end
      end
    end
  end

  def update 
    flash = {}
    @staff = Staff.find(params[:id])

    if @staff.update_attributes(params[:staff])
      flash[:notice] = "Docente actualizado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Staff: #{@staff.id},#{@staff.first_name} #{@staff.last_name}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else 
            redirect_to @staff
          end
        end
      end
    else
      flash[:error] = "Error al actualizar al docente."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @staff.errors
            render :json => json, :status => :unprocessable_entity
          else 
            redirect_to @staff
          end
        end
      end
    end
  end

  def change_image
    @staff = Staff.find(params[:id])
    render :layout => 'standalone'
  end

  def upload_image
    flash = {}
    @staff = Staff.find(params[:id])
    if @staff.update_attributes(params[:staff])
      flash[:notice] = "Imagen actualizada."
    else
      flash[:error] = "Error al actualizar la imagen."
    end

    redirect_to :action => 'change_image', :id => params[:id]
  end

  def new_seminar
    @staff = Staff.find(params[:id])
    render :layout => 'standalone'
  end

  def create_seminar
    flash = {}
    @staff = Staff.find(params[:staff_id])
    if @staff.update_attributes(params[:staff])
      flash[:notice] = "Nuevo seminario creado."
    else
      flash[:error] = "Error al crear el seminario."
    end
    render :layout => 'standalone'
  end

  def edit_seminar
    @staff = Staff.find(params[:id])
    @seminar = Seminar.find(params[:seminar_id])
    render :layout => false
  end

  def seminars_table
    @staff = Staff.find(params[:id])
    render :layout => false
  end

  def new_external_course
    @staff = Staff.find(params[:id])
    render :layout => 'standalone'
  end

  def create_external_course
    flash = {}
    @staff = Staff.find(params[:staff_id])
    if @staff.update_attributes(params[:staff])
      flash[:notice] = "Nuevo external_courseio creado."
    else
      flash[:error] = "Error al crear el external_courseio."
    end
    render :layout => 'standalone'
  end

  def edit_external_course
    @staff = Staff.find(params[:id])
    @external_course = ExternalCourse.find(params[:external_course_id])
    render :layout => false
  end

  def external_courses_table
    @staff = Staff.find(params[:id])
    render :layout => false
  end

  def new_lab_practice
    @staff = Staff.find(params[:id])
    render :layout => 'standalone'
  end

  def create_lab_practice
    flash = {}
    @staff = Staff.find(params[:staff_id])
    if @staff.update_attributes(params[:staff])
      flash[:notice] = "Nueva practica creado."
    else
      flash[:error] = "Error al crear la practica"
    end
    render :layout => 'standalone'
  end

  def edit_lab_practice
    @staff = Staff.find(params[:id])
    @lab_practice = LabPractice.find(params[:lab_practice_id])
    render :layout => false
  end

  def lab_practices_table
    @staff = Staff.find(params[:id])
    render :layout => false
  end

  def schedule_table
    @is_pdf = false 
    @id	    = params[:id]
			
    @start_date = params[:start_date]
    @end_date   = params[:end_date]
      
    if @start_date.blank? or @end_date.blank?
      @error = 1 # No se pueden mandar fechas vacias
      render :layout => false and return
    end 

    @sd  = Date.parse(@start_date)
    @ed  = Date.parse(@end_date)

    @diference    = @ed - @sd

    if @diference.to_i < 0
      @error  = 2 #La fecha inicial es mayor que la final
      render :layout => false and return
    end
    
    @tcs = TermCourseSchedule.where("staff_id = :staff_id AND ((start_date <= :start_date AND :start_date <= end_date) OR (start_date <= :end_date AND :end_date <= end_date) OR (start_date > :start_date AND :end_date > end_date))",{:staff_id => @id,:start_date => @start_date,:end_date => @end_date});
			
    @schedule = Hash.new
    (4..22).each do |i|
      @schedule[i] = Array.new
      (1..7).each do |j|
        @schedule[i][j] = Array.new
      end
    end

    n = 0
    courses = Hash.new
    @min_hour = 24
    @max_hour = 1
			
    @tcs.each do |session_item| 
      hstart	= session_item.start_hour.hour
      hend   	= session_item.end_hour.hour - 1
					
      (hstart..hend).each do |h|
        if courses[session_item.term_course.course.id].nil?
          n += 1
          courses[session_item.term_course.course.id] = n
        end
   
        comments = ""
        if session_item.start_date != session_item.term_course.term.start_date
          comments += "Inicia: #{l session_item.start_date, :format => :long}\n"
        end

        if session_item.end_date != session_item.term_course.term.end_date
          comments += "Finaliza: #{l session_item.end_date, :format => :long}"
        end
    
        staff_name = session_item.staff.full_name rescue 'Sin docente'
	
        details = {
          "name" 	   => session_item.term_course.course.name,
          "staff_name" => staff_name,
          "comments"   => comments,
          "id"         => session_item.id,
          "n"          => courses[session_item.term_course.course.id]
       }

        @schedule[h][session_item.day] << details
        @min_hour = h if h < @min_hour
        @max_hour = h if h > @max_hour
      end
    end
			
    respond_with do |format|
      format.html do
        render :layout => false
      end
    
      format.pdf do
        institution = Institution.find(1)
        @logo = institution.image_url(:medium).to_s
        @is_pdf = true
        html = render_to_string(:layout => false , :action => "schedule_table.html.haml")
        kit = PDFKit.new(html, :page_size => 'Letter')
        #kit.stylesheets << "#{Rails.root}/public/stylesheets/compiled/pdf.css"
        kit.stylesheets << "http://posgrado.cimav.edu.mx" + view_context.asset_path('pdf.css')
        filename = "horario-#{@tcs[0].staff.id}-#{@tcs[0].term_course.term.id}.pdf"
        send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        return # to avoid double render call
      end   
    end
  end
  
  def id_card
    @time    = Time.now + 31536000
    @staff = Staff.find(params[:id])
    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.pdf do
        institution = Institution.find(1)
        @logo = institution.image_url(:medium).to_s
        @is_pdf = true
        html = render_to_string(:layout => false , :action => "id_card.html.haml")
        kit = PDFKit.new(html, :page_size => 'Legal', :orientation => 'Landscape', :margin_top    => '0',:margin_right  => '0', :margin_bottom => '0', :margin_left   => '0')
        # kit.stylesheets << "#{Rails.root}/public/stylesheets/compiled/card.css"
        kit.stylesheets << "http://posgrado.cimav.edu.mx" + view_context.asset_path('card.css')
        filename = "ID-#{@staff.id}.pdf"
        send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        return # to avoid double render call
      end
    end
  end
  
  def files
    @staff = Staff.includes(:staff_file).find(params[:id])
    @staff_file = StaffFile.new
    render :layout => 'standalone'
  end

  def upload_file
    flash = {}
    params[:staff_file]['file'].each do |f|
      @staff_file = StaffFile.new
      @staff_file.staff_id = params[:staff_file]['staff_id']
      @staff_file.file = f
      @staff_file.description = f.original_filename
      if @staff_file.save
        flash[:notice] = "Archivo subido exitosamente."
      else
        flash[:error] = "Error al subir archivo."
      end
    end

    redirect_to :action => 'files', :id => params[:id]
  end

  def file
    s = Staff.find(params[:id])
    sf = s.staff_file.find(params[:file_id]).file
    send_file sf.to_s, :x_sendfile=>true
  end 

  def delete_file
  end


end
