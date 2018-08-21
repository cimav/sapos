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
                   'Tipo' => s.get_type,
                 }
        end
        column_order = ["Numero_Empleado","Título","Nombre","Apellidos","Correo_Elec","Sexo","Fecha_Nac","CVU","SNI","Estado","Tipo "]
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

  def evaluation
    @staffs  = Staff.includes(:term_courses=>:term).where(:status=>0).where("terms.name like '%2018-1%'")
    numeric = !params[:numeric].to_i.zero?
    
    rows = Array.new

    @staffs.each do |s|
      s.term_courses.each do |tc|
        averages= get_teacher_evaluation_averages(tc,numeric)
        if !(averages["question1"].nil?)
          logger.info "################################# averages: #{averages["question1"]}"

          if numeric
            rows << {
              "Nombre"=>s.full_name,
              "Curso"=>tc.course.name,
              "Grupo"=>tc.group,
              "Ciclo Escolar"=>tc.term.name,
              "Pregunta1" => averages["question1"],
              "Pregunta2" => averages["question2"],
              "Pregunta3" => averages["question3"],
              "Pregunta4" => averages["question4"],
              "Pregunta5" => averages["question5"],
              "Pregunta6" => averages["question6"],
              "Pregunta7" => averages["question7"],
              "Pregunta8" => averages["question8"],
              "Pregunta9" => averages["question9"],
              "Pregunta10" => averages["question10"],
              "Pregunta11" => averages["question11"],
              "Pregunta12" => averages["question12"],
            } 
          else
            rows << {
              "Nombre"=>s.full_name,
              "Curso"=>tc.course.name,
              "Grupo"=>tc.group,
              "Ciclo Escolar"=>tc.term.name,
              "Pregunta1" => TeacherEvaluation::ANSWERS[averages["question1"]],
              "Pregunta2" => TeacherEvaluation::ANSWERS[averages["question2"]],
              "Pregunta3" => TeacherEvaluation::ANSWERS[averages["question3"]],
              "Pregunta4" => TeacherEvaluation::ANSWERS[averages["question4"]],
              "Pregunta5" => TeacherEvaluation::ANSWERS[averages["question5"]],
              "Pregunta6" => TeacherEvaluation::ANSWERS[averages["question6"]],
              "Pregunta7" => TeacherEvaluation::ANSWERS[averages["question7"]],
              "Pregunta8" => TeacherEvaluation::ANSWERS[averages["question8"]],
              "Pregunta9" => TeacherEvaluation::ANSWERS[averages["question9"]],
              "Pregunta10" => TeacherEvaluation::ANSWERS[averages["question10"]],
              "Pregunta11" => TeacherEvaluation::ANSWERS[averages["question11"]],
              "Pregunta12" => TeacherEvaluation::ANSWERS[averages["question12"]],
            } 
          end
        end
      end
    end

    column_order=["Nombre","Curso","Grupo","Ciclo Escolar","Pregunta1","Pregunta2","Pregunta3","Pregunta4","Pregunta5","Pregunta6","Pregunta7","Pregunta8","Pregunta9","Pregunta10","Pregunta11","Pregunta12"]
    to_excel(rows,column_order,"Evaluacion","Evaluacion")
  end#end evaluation

  def get_teacher_evaluation_averages(tc,numeric)
    averages = Hash.new
    tc.teacher_evaluations.each do |te|
      (1..12).each do |n|
        averages["sum#{n}"] = averages["sum#{n}"].to_f + te["question#{n}"].to_f
      end
    end
    
    if !(averages["sum1"].nil?)
      (1..12).each do |n|
        if numeric
          averages["question#{n}"] = (averages["sum#{n}"]/tc.teacher_evaluations.size).to_f.round(2)
        else
          averages["question#{n}"] = (averages["sum#{n}"]/tc.teacher_evaluations.size).to_f.round
        end
        averages.delete("sum#{n}")
      end
    end
   
    return averages
  end
  #def get_teacher_evaluation_averages(tc)

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

  def certificates
    staff_id = params[:id]
    @staff   = Staff.find(staff_id)

    @sign    = params[:sign_id]
    city     = params[:city]
    dir            = t(:directory)
    options        = {}
    options[:city] = city

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
    end

    ##### GENERO GRAMATICAL #####
    if @staff.gender == 'F'
      @genero   = "a"
      @genero2  = "la"
      @sgenero3 = "a la"
    elsif @staff.gender == 'H'
      @genero   = "o"
      @genero2  = "el"
      @sgenero3 = "al"
    else
      @genero   = "x"
      @genero2  = "x"
      @sgenero3 = "x"
    end

    if @sgender == "F"
      @sgenero  = "a"
      @sgenero2 = "la"
    elsif @sgender == "M"
      @sgenero  = "o"
      @sgenero2 = "el"
    else
      @sgenero  = "x"
      @sgenero2 = "x"
    end

    ################################ CONSTANCIA DE DIRECTOR DE TESIS ##################################
    if params[:type] == "dir_tesis"
      start_date = params[:start_date]
      end_date   = params[:end_date]
      options[:cert_type] = Certificate::STAFF_THESIS_DIR
      options[:text]      = "Por medio de la presente tengo el agrado de extender la presente constancia #{@sgenero3} #{@staff.title} #{@staff.full_name}"
      options[:text]      << " quien participó como Director de tesis de los siguientes estudiantes:"
      options[:filename]  =  "constancia-director-tesis-#{@staff.id}.pdf"

      if !start_date.blank?
        options[:students] = Student.where(:supervisor=>@staff.id).where("(start_date <= :start_date AND :start_date <= end_date) OR (start_date <= :end_date AND :end_date <= end_date) OR (start_date > :start_date AND :end_date > end_date)",{:start_date=>start_date,:end_date=>end_date})
      else  
        options[:students] = Student.where(:supervisor=>@staff.id)
      end
    ################################ CONSTANCIA DE CO-DIRECTOR DE TESIS ##################################
    elsif params[:type] == "co_dir_tesis"
      start_date = params[:start_date]
      end_date   = params[:end_date]
      options[:cert_type] = Certificate::STAFF_THESIS_DIR
      options[:text]      = "Por medio de la presente tengo el agrado de extender la presente constancia #{@sgenero3} #{@staff.title} #{@staff.full_name}"
      options[:text]      << " quien participó como Co-Director de tesis de los siguientes estudiantes:"
      options[:filename]  =  "constancia-director-tesis-#{@staff.id}.pdf"
      options[:co_director] = true

      if !start_date.blank?
        options[:students] = Student.where(:co_supervisor=>@staff.id).where("(start_date <= :start_date AND :start_date <= end_date) OR (start_date <= :end_date AND :end_date <= end_date) OR (start_date > :start_date AND :end_date > end_date)",{:start_date=>start_date,:end_date=>end_date})
      else  
        options[:students] = Student.where(:co_supervisor=>@staff.id)
      end
    
    ################################ CONSTANCIA COMO SINODAL ##################################
    elsif params[:type] == "sinodal"
      start_date = params[:start_date]
      end_date   = params[:end_date]
      options[:cert_type] = Certificate::STAFF_SINODAL
      options[:text]      = "Por medio de la presente tengo el agrado de extender la presente constancia #{@sgenero3} #{@staff.title} #{@staff.full_name}"
      options[:text]      << " quien participó como sinodal de tesis de los siguientes estudiantes:"
      options[:filename]  =  "constancia-sinodal-tesis-#{@staff.id}.pdf"

      if !start_date.blank?
        options[:theses] = Thesis.where("examiner1=:staff_id OR examiner2=:staff_id OR examiner3=:staff_id OR examiner4=:staff_id OR examiner5=:staff_id",:staff_id=>@staff.id).where("(:start_date <= defence_date AND defence_date <= :end_date)",{:start_date=>start_date,:end_date=>end_date}).where(:status=>'C').order(:defence_date)
      else  
          options[:theses] = Thesis.where("examiner1=:staff_id OR examiner2=:staff_id OR examiner3=:staff_id OR examiner4=:staff_id OR examiner5=:staff_id",:staff_id=>@staff.id).order(:defence_date)
      end
    ################################ CONSTANCIA DE FORMACIÓN DE RH ##################################
    elsif params[:type] == "RH"
      start_date = params[:start_date]
      end_date   = params[:end_date]
      options[:start_date] = params[:start_date].to_date
      options[:end_date] = params[:end_date].to_date
      options[:cert_type] = Certificate::STAFF_RH
      options[:text]      = "Por medio de la presente tengo el agrado de extender la presente constancia #{@sgenero3} #{@staff.title} #{@staff.full_name}"

      if !start_date.blank?
        options[:text]      << " quien participó en la formación de recursos humanos en el periodo del <b> #{options[:start_date].day} de #{get_month_name(options[:start_date].month)} del #{options[:start_date].year} al #{options[:end_date].day} de #{get_month_name(options[:end_date].month)} del #{options[:end_date].year} </b> de los siguientes estudiantes:"
      else
        options[:text]      << " quien participó en la formación de recursos humanos de los siguientes estudiantes: "
      end  
      options[:filename]  =  "constancia-formacion-RH-#{@staff.id}.pdf"

      if !start_date.blank?
        options[:ranges]=true  
        
        as_director = Student.where(:supervisor=>@staff.id).where("status in (1,6)")
        as_director = as_director + Student.where(:supervisor=>@staff.id).joins(:thesis).where("end_date >= :start_date  AND end_date <= :end_date AND students.status in (2,5)",{:start_date=>start_date,:end_date=>end_date}).order("students.status")
        options[:active_students] = as_director

        as_co_director = Student.where(:co_supervisor=>@staff.id).where("status in (1,6)")
        as_co_director = as_co_director + Student.where(:co_supervisor=>@staff.id).joins(:thesis).where("end_date >= :start_date  AND end_date <= :end_date AND students.status in (2,5)",{:start_date=>start_date,:end_date=>end_date}).order("students.status")
        options[:active_students_co] = as_co_director

        as_external_director = Student.where(:external_supervisor=>@staff.id).where("status in (1,6)")
        as_external_director = as_external_director + Student.where(:external_supervisor=>@staff.id).joins(:thesis).where("end_date >= :start_date  AND end_date <= :end_date AND students.status in (2,5)",{:start_date=>start_date,:end_date=>end_date}).order("students.status")
        options[:active_students_external] = as_external_director        

        options[:theses] = Thesis.where("examiner1=:staff_id OR examiner2=:staff_id OR examiner3=:staff_id OR examiner4=:staff_id OR examiner5=:staff_id",:staff_id=>@staff.id).where("(:start_date <= defence_date AND defence_date <= :end_date)",{:start_date=>start_date,:end_date=>end_date}).where(:status=>'C').order(:defence_date)

        tutors = "(tutor1=:staff_id OR tutor2=:staff_id OR tutor3=:staff_id OR tutor4=:staff_id OR tutor5=:staff_id)"
        ranges = "(advance_date between :start_date and :end_date)"
        where  = "#{tutors} AND #{ranges}"
        dates  = {:staff_id=>@staff.id,:start_date=>start_date,:end_date=>end_date}
        order  = "first_name,last_name,advance_date desc"
        options[:advances] = Advance.where(:advance_type=>1).where(where,dates).order(order)
        
        tutors = "tutor1=:staff_id OR tutor2=:staff_id OR tutor3=:staff_id OR tutor4=:staff_id OR tutor5=:staff_id"
        ranges = "(:start_date <= advance_date AND advance_date <= :end_date)"
        dates  = {:start_date=>start_date,:end_date=>end_date}
        order  = "first_name,last_name"
        options[:seminars] = Advance.includes(:student).where(tutors,:staff_id=>@staff.id).where(ranges,dates).where(:advance_type=>3).where("advances.status != 'X'").order(order)

        options[:term_course_schedules] = TermCourseSchedule.where(staff_id:@staff.id).select(:term_course_id).uniq
        options[:external_courses] = ExternalCourse.where(staff_id:@staff.id).where(status:[nil,ExternalCourse::ACTIVE]).where("(start_date > :start_date AND :end_date > end_date)",{:start_date=>start_date,:end_date=>end_date})
        options[:lab_practices] = LabPractice.where(staff_id:@staff.id).where("(start_date <= :start_date AND :start_date <= end_date) OR (start_date <= :end_date AND :end_date <= end_date) OR (start_date > :start_date AND :end_date > end_date)",{:start_date=>start_date,:end_date=>end_date})
        
        ranges = "(start_date between :start_date and :end_date) OR (end_date between :start_date and :end_date)"
        order  = "first_name,last_name,internship_type_id"
        group  = "first_name,last_name,internship_type_id"
        options[:internships] = Internship.where(staff_id:@staff.id).where(ranges,{:start_date=>start_date,:end_date=>end_date}).order(order)
      else
        options[:ranges]= false
        options[:active_students] = Student.where(:supervisor=>@staff.id).where("status not in (0,4)").order(:status)
        options[:active_students_co] = Student.where(:co_supervisor=>@staff.id).where("status not in (0,4)").order(:status)
        options[:term_course_schedules] = TermCourseSchedule.where(staff_id:@staff.id).select(:term_course_id).uniq
        options[:term_courses] = TermCourse.where(staff_id:@staff.id)
        options[:external_courses] = ExternalCourse.where(staff_id:@staff.id)
        options[:lab_practices] = LabPractice.where(staff_id:@staff.id)
        #options[:advances] = Advance.where("tutor1=:staff_id OR tutor2=:staff_id OR tutor3=:staff_id OR tutor4=:staff_id OR tutor5=:staff_id",:staff_id=>@staff.id).where(:advance_type=>'1').order(:advance_date)
        #options[:seminars] = Advance.where("tutor1=:staff_id OR tutor2=:staff_id OR tutor3=:staff_id OR tutor4=:staff_id OR tutor5=:staff_id",:staff_id=>@staff.id).where(:advance_type=>'3').order(:advance_date)
        options[:theses] = Thesis.where("examiner1=:staff_id OR examiner2=:staff_id OR examiner3=:staff_id OR examiner4=:staff_id OR examiner5=:staff_id",:staff_id=>@staff.id).order(:defence_date)
        options[:internships] = Internship.where(staff_id:@staff.id,status: 1).order(:start_date)
      end
    end

    generate_certificate(options)
  end#def certificates

  def generate_certificate(options)
    @t = t(:date)
    @rectangles = false
    ## OPTIONS
    @options     = params[:options]
    if @options.eql? "1"
      @op_asesor = 1
    else
      @op_asesor = 0
    end

    time = Time.new
    year = time.year.to_s

    background = "#{Rails.root.to_s}/private/prawn_templates/membretada.png"
    @consecutivo = get_consecutive(@staff, time, options[:cert_type])
    @rails_root  = "#{Rails.root}"
    @year_s      = year[2,4]
    @year        = year
    @days        = time.day.to_s
    @month       = get_month_name(time.month)

    Prawn::Document.new(:background => background, :background_scale=>0.36, :margin=>[130,50,65,50] ) do |pdf|
      pdf.font_size 10
      x = 232
      y = 664 #664
      w = 255
      h = 50
        
      if @rectangles then pdf.stroke_rectangle [x,y], w, h end
      pdf.text "Coordinación de estudios de Posgrado\nNo° de Oficio  <b>PO - #{@consecutivo}/#{@year}</b>\n#{options[:city]}, a #{@days} de #{@month} de #{@year}.", :inline_format=>true, :align=>:right, :width=>w, :height=>h

      pdf.font_size 11
      y = y - 70
      x = 10
      h = 50

      pdf.text "A quien corresponda\nPresente:", :align=>:left,:valign=>:top, :width=>w, :height=>h,:inline_format=>true

      y = y - 60
      h = 220
      w = 500

      pdf.text "\n"
      pdf.text options[:text], :align=>:justify, :inline_format=>true              
      pdf.text "\n"
   
      ################################ CONSTANCIA DE DIRECTOR DE TESIS ##################################
      if options[:cert_type].eql? Certificate::STAFF_THESIS_DIR
        @students = options[:students]
         
        data = []
        data << [{:content=>"<b>NOMBRE</b>",:align=>:center},{:content=>"<b>PROGRAMA</b>",:align=>:center},{:content=>"<b>TESIS</b>",:align=>:center},{:content=>"<b>ESTATUS</b>",:align=>:center}]

        @students.each do |s|
          data << [s.full_name,s.program.name,s.thesis.title,Student::STATUS[s.status]]
        end

        if options[:co_director]
          text = "<b>Participación como co-director de tesis</b>\n"
        else
          text = "<b>Participación como director de tesis</b>\n"
        end
        pdf.text text, :align=>:center, :inline_format=>true              
        
        tabla = pdf.make_table(data,:width=>510,:cell_style=>{:size=>10,:padding=>2,:inline_format => true,:border_width=>1},:position=>:center,:column_widths => [100,100,240,70])
        tabla.draw
      ################################ CONSTANCIA COMO SINODAL ##################################
      elsif options[:cert_type].eql? Certificate::STAFF_SINODAL
        @theses = options[:theses]
        data = []
        get_month_name(time.month)
        data << [{:content=>"<b>NOMBRE</b>",:align=>:center},{:content=>"<b>PROGRAMA</b>",:align=>:center},{:content=>"<b>TESIS</b>",:align=>:center},{:content=>"<b>FECHA DE DEFENSA</b>",:align=>:center}]

        @theses.each do |t|
          defence_month = get_month_name(t.defence_date.month)
          data << [t.student.full_name ,t.student.program.name,t.title,t.defence_date.strftime("%-d de #{defence_month} de %Y")]
        end
        
        pdf.text "<b>Participación como sinodal</b>\n", :align=>:center, :inline_format=>true              
        tabla = pdf.make_table(data,:width=>500,:cell_style=>{:size=>8,:padding=>2,:inline_format => true,:border_width=>1},:position=>:center,:column_widths => [100,95,200,105])
        tabla.draw
      ##################################### CONSTANCIA FORMACIÓN DE RH ################################################################
      elsif options[:cert_type].eql? Certificate::STAFF_RH

        # Alumnos como director de tesis
        @students = options[:active_students]
        @graduate_students = options[:graduate_students]
        if @students.size > 0
          data = []
          data_helper = []
          data << [{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>ESTATUS</b>", :align => :center}]

          @students.each do |s|
            if s.status.eql? 5 ##  Para que Egresado No Graduado salga como Egresado
              data_helper << [s.full_name, s.program.name, "Egresado"]
            else
              data << [s.full_name, s.program.name, Student::STATUS[s.status]]
            end
          end

          pdf.text "<b>Participación como director de tesis</b>\n", :align => :center, :inline_format => true
          tabla = pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center)
          tabla.draw
        end

        # Alumnos como co-director de tesis
        @students = options[:active_students_co]
        @graduate_students = options[:graduate_students_co]
        if @students.size > 0
          data = []
          data << [{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>ESTATUS</b>", :align => :center}]

          @students.each do |s|
            data << [s.full_name, s.program.name, Student::STATUS[s.status]]
          end

          pdf.text "\n<b>Participación como co-director de tesis</b>\n", :align => :center, :inline_format => true
          tabla = pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center)
          tabla.draw
        end

        # Alumnos como director externo
        @students = options[:active_students_external]
        @graduate_students = options[:active_students_external]
        if @students.size > 0
          data = []
          data << [{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>ESTATUS</b>", :align => :center}]

          @students.each do |s|
            data << [s.full_name, s.program.name, Student::STATUS[s.status]]
          end

          pdf.text "\n<b>Participación como director externo</b>\n", :align => :center, :inline_format => true
          tabla = pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center)
          tabla.draw
        end


        # tesis como sinodal
        @theses = options[:theses]

        if @theses.size > 0
          data = []
          get_month_name(time.month)
          data << [{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>FECHA DE DEFENSA</b>", :align => :center}]

          @theses.each do |t|
            defence_month = get_month_name(t.defence_date.month)
            data << [t.student.full_name, t.student.program.name, t.defence_date.strftime("%-d de #{defence_month} de %Y")]
          end

          pdf.text "\n<b>Participación como sinodal</b>\n", :align => :center, :inline_format => true
          tabla = pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [190, 190, 120])
          tabla.draw
        end

        # avances como comité tutoral de Avance Programático
        active_advances = []
        active_advances = options[:advances]
      
        if active_advances.size > 0
          data = []
          get_month_name(time.month)


          approved = false
          nombre_anterior = nil
          program_id_anterior = nil

          active_advances.each do |a|
            if ((nombre_anterior.eql? a.student.full_name_cap)&(program_id_anterior.eql? a.student.program_id))
              approved = false
            else
              approved = true
            end

            if approved
              advance_month = get_month_name(a.advance_date.month)
              data << [a.student.full_name_cap, a.student.program.name, a.advance_date.strftime("%-d de #{advance_month} de %Y"), a.advance_date]
            
              nombre_anterior     = a.student.full_name_cap
              program_id_anterior = a.student.program_id
            end
          end 

          ## ordenando por la tercera fila que es la fecha directo de db
          data.sort!{|x,y|x[3]<=>y[3]}
          ## eliminando el registro de fecha de cada fila porque sino truena la tabla
          data.each do |d|
            d.delete_at(3)
          end

          ## insertando cabecera con unshift
          data.unshift([{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>FECHA DE AVANCE</b>", :align => :center}])

          pdf.text "\n<b>Participación como comité tutoral</b>\n", :align => :center, :inline_format => true
          tabla = pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [190, 185, 125])
          tabla.draw
        end

        # Seminaros departamentales como comité tutoral         
        @seminars = options[:seminars]
        
        if @seminars.size > 0
          data = []
          get_month_name(time.month)
          data << [{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>FECHA DE AVANCE</b>", :align => :center}]

          @seminars.each do |s|
            advance_month = get_month_name(s.advance_date.month)
            data << [s.student.full_name, s.student.program.name, s.advance_date.strftime("%-d de #{advance_month} de %Y")]
          end

          pdf.text "\n<b>Seminarios departamentales</b>\n", :align => :center, :inline_format => true
          tabla = pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [190, 185, 125])
          tabla.draw
        end

        # clases impartidas
        @term_course_schedules = options[:term_course_schedules]

        if @term_course_schedules.size > 0
          data = []
          data << [{:content => "<b>CLASE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>FECHA DE INICIO</b>", :align => :center}]

          @term_course_schedules.each do |tcs|
            term_course = tcs.term_course

            if !term_course.nil?
              if term_course.status != TermCourse::DELETED
                if options[:ranges]
                  if (term_course.term.start_date.between?(options[:start_date],options[:end_date]))||(term_course.term.end_date.between?(options[:start_date],options[:end_date]))
                    term_month = get_month_name(term_course.term.start_date.month)
                    data << ["#{term_course.course.name}", term_course.term.program.name, term_course.term.start_date.strftime("%-d de #{term_month} de %Y")]
                  end
                else
                  term_month = get_month_name(term_course.term.start_date.month)
                  data << [term_course.course.name, term_course.term.program.name, term_course.term.start_date.strftime("%-d de #{term_month} de %Y")]
                end
              end
            else
              logger.info "################# No se que pasa aquí"  
              #data << [tcs.id.to_s,"######","######"]
            end

          end

          pdf.text "\n<b>Clases impartidas</b>\n", :align => :center, :inline_format => true
          tabla = pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [200, 195, 105])
          tabla.draw
        end

        # Cursos o talleres
        @external_courses = options[:external_courses]

        if @external_courses.size > 0
          data = []
          data << [{:content => "<b>TÍTULO</b>", :align => :center}, {:content => "<b>FECHA DE INICIO</b>", :align => :center}, {:content => "<b>TIPO</b>", :align => :center}]

          @external_courses.each do |e|
            course_month = get_month_name(e.start_date.month)
            data << [e.title, e.start_date.strftime("%-d de #{course_month} de %Y"), e.get_type]
          end

          pdf.text "\n<b>Cursos o talleres</b>\n", :align => :center, :inline_format => true
          tabla = pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [300, 100, 100])
          tabla.draw
        end

        # Prácticas de laboratorio
        @lab_practices = options[:lab_practices]

        if @lab_practices.size > 0
          data = []
          get_month_name(time.month)
          data << [{:content => "<b>Título</b>", :align => :center}, {:content => "<b>FECHA DE INICIO</b>", :align => :center}, {:content => "<b>TIEMPO DE PRÁCTICA</b>", :align => :center}]

          @lab_practices.each do |l|
            practice_month = get_month_name(l.start_date.month)
            data << [l.title, l.start_date.strftime("%-d de #{practice_month} de %Y"), l.hours]
          end

          pdf.text "\n<b>Prácticas de laboratorio</b>\n", :align => :center, :inline_format => true
          tabla = pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [280, 100, 120])
          tabla.draw

        end

        # Servicios CIMAV
        @internships= options[:internships]
        
        if @internships.size > 0
          data = []
          data << [{:content => "<b>Nombre</b>", :align => :center}, {:content => "<b>Tipo de Servicio</b>", :align => :center}]          

          approved = false
          nombre_anterior = nil
          i_type_anterior = nil
          @internships.each do |i|
            if ((i_type_anterior.eql? i.internship_type_id)&&(nombre_anterior.eql? i.full_name_cap))
              approved = false
            else
              approved = true
            end

            if approved
              data << [i.full_name_cap, i.internship_type.name]
            
              nombre_anterior = i.full_name_cap
              i_type_anterior = i.internship_type_id
            end
          end 

          pdf.text "\n<b>Servicios CIMAV</b>\n", :align => :center, :inline_format => true
          tabla = pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [280, 220])
          tabla.draw
        end
      end#elsif

      pdf.text "\nSe extiende la presente constancia a petición del interesado, para los fines legales que haya lugar."

      ############################## FIRMA ##############################
      @atentamente = "\n\n<b>A t e n t a m e n t e\n\n\n#{@firma}\n#{@puesto}</b>"
      pdf.text @atentamente, :align=>:center,:inline_format=>true
      ############################## ###### ##############################

      pdf.number_pages "Página <page> de <total>", {:at=>[0, 0],:align=>:right,:size=>8}


      filename = options[:filename]
      if Rails.env.production?
        send_data pdf.render, filename: filename, type: "application/pdf", disposition: "attachment"
      else
        ## linea para desarrollo (es más productivo actualizar la página que estar descargando archivos)
        send_data pdf.render, filename: filename, type: "application/pdf", disposition: "inline"
      end
      
      
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
    certificate.type_id         = type
    certificate.save

    return "%03d" % maximum
  end

  def admission_exams_table
    @staff = Staff.find(params[:id])
    render :layout => false
  end

  def new_admission_exam
    @staff = Staff.find(params[:id])
    render :layout => false
  end

  def edit_admission_exam
    @staff = Staff.find(params[:id])
    @exam = AdmissionExam.find(params[:admission_exam_id])
    render :layout => false
  end

  def create_admission_exam
    flash = {}
    @staff = Staff.find(params[:staff_id])
    if @staff.update_attributes(params[:staff])
      flash[:notice] = "Examen de admisión registrado"
    else
      flash[:error] = "Error al registrar el examen de admisión."
    end
    render :layout => 'standalone'
  end


  def delete_admission_exam
    flash = {}
    @exam  = AdmissionExam.find(params[:admission_exam_id])
    @exam.status = AdmissionExam::DELETED
    if @exam.save
      flash[:notice] = "Examen de admisión eliminado"
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Delete Admission Exam: #{@exam.id}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:admission_exam_id] = params[:admission_exam_id]
            render :json => json
          else
            redirect_to @staff
          end
        end
      end
    else
      flash[:error] = "Error al eliminar examen de admisión"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @exam.errors
            json[:errors_full] = @exam.errors.full_messages
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @staff
          end
        end
      end
    end
  end

end
