# coding: utf-8
class StaffsController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
    @aareas       = get_areas(current_user)
    @institutions = Institution.order('name')
    if current_user.access == User::OPERATOR
      @areas        = Area.where(:id=> @aareas).order('name')
    elsif current_user.access == User::MANAGER
      @areas  = Area.order('name')
    else
      @areas        = Area.where(:id=> @aareas).order('name')
    end
  end

  def live_search
    @staffs = Staff.order("first_name")

    @aareas = get_areas(current_user)
    if current_user.access == User::OPERATOR
      @staffs = Staff.order("first_name").where(:area_id=>@aareas)
    elsif current_user.access == User::MANAGER
      @staffs = Staff.order("first_name")
    else
      @staffs = Staff.order("first_name").where(:area_id=>@aareas)
    end



    if params[:staff_type] != '' then
      @staffs = @staffs.where(:staff_type => params[:staff_type])
    end

    if params[:institution] != '0' then
      @staffs = @staffs.where(:institution_id => params[:institution])
    end

    if params[:area] != '' then
      @staffs = @staffs.where(:area_id => params[:area])
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

    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.xls do
        rows = Array.new
        @staffs.collect do |s|
          rows << {'Numero_Empleado' => s.employee_number,
                   'Título' => s.title,
                   'Nombre' => s.first_name,
                   'Apellidos' => s.last_name,
                   'Correo_Elec' => s.email,
                   'Sexo' => s.gender,
                   'Fecha_Nac' => s.date_of_birth,
                   'CVU' => s.cvu,
                   'SNI' => s.sni,
                   'Estado' => s.status,
                   'Estado' => s.get_type,
                 }
        end
        column_order = ["Numero_Empleado","Título","Nombre","Apellidos","Correo_Elec","Sexo","Fecha_Nac","CVU","SNI","Estado"]
        to_excel(rows,column_order,"Docentes","Docentes")
      end
    end
  end

  def report
    @staffs = Staff.includes(:area).where("area_id in (?)",[10,11,12,13,14,15]).order(:area_id)
    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.xls do
        rows = Array.new
        @staffs.collect do |s|
          active   = s.supervised.joins(:program).where(:status => Student::ACTIVE).where("programs.program_type=2").count + s.co_supervised.joins(:program).where(:status => Student::ACTIVE).where("programs.program_type=2").count
          baja     = s.supervised.joins(:program).where(:status => [Student::UNREGISTERED,Student::INACTIVE]).where("programs.program_type=2").count + s.co_supervised.joins(:program).where(:status => [Student::UNREGISTERED,Student::INACTIVE]).where("programs.program_type=2").count

          et_master_percent = 0  ## et = eficiencia terminal
          et_master_counter = 0
          g_master_avg      = 0
          g_master_sum      = 0
          counter           = 0
          students = s.supervised.joins(:program).where(:status => [Student::GRADUATED]).where("programs.level=1 AND programs.program_type=2") + s.co_supervised.joins(:program).where(:status => [Student::GRADUATED]).where("programs.level=1 AND programs.program_type=2")

          if students.size>0
            students.each do |st|
              logger.info "INFOOOOOOOOOOOOOO #{s.full_name} | #{st.full_name} #{st.time_studies}"
              st_time_studies = st.time_studies
              g_master_sum = g_master_sum + st_time_studies
              if st_time_studies<=24
                et_master_counter = et_master_counter + 1
              end
              counter = counter + 1
            end
            g_master_avg      = g_master_sum/counter
          end
          
          et_doc_percent = 0
          et_doc_counter = 0
          g_doc_avg = 0
          g_doc_sum = 0
          counter   = 0
          students  = s.supervised.joins(:program).where(:status => [Student::GRADUATED]).where("programs.level=2 AND programs.program_type=2") + s.co_supervised.joins(:program).where(:status => [Student::GRADUATED]).where("programs.level=2 AND programs.program_type=2")

          if students.size>0
            students.each do |st|
              logger.info "INFOOOOOOOOOOOOOODOC #{s.full_name} | #{st.full_name} #{st.time_studies}"
              st_time_studies = st.time_studies
              g_doc_sum = g_doc_sum + st_time_studies
              if st_time_studies<=48
                et_doc_counter = et_doc_counter + 1
              end
              counter = counter + 1
            end
            g_doc_avg = g_doc_sum/counter
          end
          
          g_master = s.supervised.joins(:program).where(:status => [Student::GRADUATED]).where("programs.level=1 AND programs.program_type=2").count + s.co_supervised.joins(:program).where(:status => [Student::GRADUATED]).where("programs.level=1 AND programs.program_type=2").count
          g_doc    = s.supervised.joins(:program).where(:status => [Student::GRADUATED]).where("programs.level=2 AND programs.program_type=2").count + s.co_supervised.joins(:program).where(:status => [Student::GRADUATED]).where("programs.level=2 AND programs.program_type=2").count

          the_status = [Student::GRADUATED,Student::ACTIVE,Student::UNREGISTERED,Student::INACTIVE]
          all_master = s.supervised.joins(:program).where(:status => the_status).where("programs.level=1 AND programs.program_type=2").count + s.co_supervised.joins(:program).where(:status => the_status).where("programs.level=1 AND programs.program_type=2").count
          all_doc = s.supervised.joins(:program).where(:status => the_status).where("programs.level=2 AND programs.program_type=2").count + s.co_supervised.joins(:program).where(:status => the_status).where("programs.level=2 AND programs.program_type=2").count

          et_master_percent = (et_master_counter.to_f/all_master.to_f)*100 rescue 0
          et_doc_percent    = (et_doc_counter.to_f/all_doc.to_f)*100 rescue 0

          rows << {'Area' => s.area.name,
                   'Nombre' => s.full_name,
                   'Activos' => active,
                   'Bajas' => baja,
                   'GraduadosM' => g_master,
                   'GraduadosD' => g_doc,
                   'PGradMaestriaMeses' => g_master_avg,
                   'PGradDoctoradoMeses' => g_doc_avg,
                   'ETMaestria' => et_master_percent.round(2),
                   'ETDoctorado' => et_doc_percent.round(2)
                 }
        end

        column_order = ["Area","Nombre","Activos","Bajas","GraduadosM","GraduadosD","PGradMaestriaMeses","PGradDoctoradoMeses","ETMaestria","ETDoctorado"]
        to_excel(rows,column_order,"Docentes","Docentes")
      end ## end format
    end ## end respond_with
  end ## end reporte

  def show
    @aareas       = get_areas(current_user)
    @staff        = Staff.find(params[:id])
    @countries    = Country.order('name')
    @institutions = Institution.order('name')
    @states       = State.order('code')

    if current_user.access == User::OPERATOR
      @areas        = Area.where(:id=> @aareas).order('name')
    elsif current_user.access == User::MANAGER
      @areas  = Area.order('name')
    else
      @areas        = Area.where(:id=> @aareas).order('name')
    end
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

  def delete_seminar
    flash = {}
    @seminar = Seminar.find(params[:seminar_id])
    @seminar.status = 2
    if @seminar.save
      flash[:notice] = "Seminario eliminado"
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Delete Seminar: #{@seminar.id}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:seminar_id] = params[:seminar_id]
            render :json => json
          else
            redirect_to @staff
          end
         end
       end
    else
      flash[:error] = "Error al eliminar seminario"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @seminar.errors
            json[:errors_full] = @seminar.errors.full_messages
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @staff
          end
        end
      end
    end
  end

  def delete_external_course
    flash = {}
    @external_course  = ExternalCourse.find(params[:external_course_id])
    @external_course.status = 2
    if @external_course.save
      flash[:notice] = "Curso externo eliminado"
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Delete External Course: #{@external_course.id}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:external_course_id] = params[:external_course_id]
            render :json => json
          else
            redirect_to @staff
          end
         end
       end
    else
      flash[:error] = "Error al eliminar curso externo"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @external_course.errors
            json[:errors_full] = @external_course.errors.full_messages
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @staff
          end
        end
      end
    end
  end

  def delete_lab_practice
    flash = {}
    @lab_practice  = LabPractice.find(params[:lab_practice_id])
    @lab_practice.status = 2
    if @lab_practice.save
      flash[:notice] = "Práctica eliminada"
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Delete Lab Practice: #{@lab_practice.id}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:lab_practice_id] = params[:lab_practice_id]
            render :json => json
          else
            redirect_to @staff
          end
         end
       end
    else
      flash[:error] = "Error al eliminar la practica"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @lab_practice.errors
            json[:errors_full] = @lab_practice.errors.full_messages
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @staff
          end
        end
      end
    end
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

    @tcs = TermCourseSchedule.joins(:term_course).where("term_course_schedules.staff_id = :staff_id AND term_courses.status=1 AND term_course_schedules.status=1 AND ((start_date <= :start_date AND :start_date <= end_date) OR (start_date <= :end_date AND :end_date <= end_date) OR (start_date > :start_date AND :end_date > end_date))",{:staff_id => @id,:start_date => @start_date,:end_date => @end_date});

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
          "classroom"  => session_item.classroom.name,
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
        kit.stylesheets << "#{Rails.root}#{Sapos::Application::ASSETS_PATH}pdf.css"
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
        kit.stylesheets << "#{Rails.root}#{Sapos::Application::ASSETS_PATH}card.css"
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
