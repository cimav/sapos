# coding: utf-8
class StudentsController < ApplicationController
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
    else
      @programs     = Program.joins(:permission_user).where(:permission_users=>{:user_id=>current_user.id}).order('name')
    end

    @supervisors = Staff.find_by_sql "SELECT id, first_name, last_name FROM staffs WHERE id IN (SELECT supervisor FROM students UNION SELECT co_supervisor FROM students) ORDER BY first_name, last_name"
  end

  def live_search
    if current_user.program_type==Program::ALL
      @students = Student.order("first_name").includes(:program)
    else
      @students = Student.joins(:program => :permission_user).where(:permission_users=>{:user_id=>current_user.id}).order("first_name").includes(:program)
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

    if params[:status] == 'todos_activos' then
      @students = @students.where("status = #{Student::ACTIVE}")
    end

    if params[:status] == 'activos_inscritos' then
      @students = @students.where("status = #{Student::ACTIVE} AND students.id IN (SELECT student_id FROM terms INNER JOIN term_students ON terms.id = term_id WHERE terms.status IN (#{Term::OPEN}, #{Term::PROGRESS}, #{Term::GRADING}))")
    end

    if params[:status] == 'activos_no_inscritos' then
      @students = @students.where("status = #{Student::ACTIVE} AND students.id NOT IN (SELECT student_id FROM terms INNER JOIN term_students ON terms.id = term_id WHERE terms.status IN (#{Term::OPEN}, #{Term::PROGRESS}, #{Term::GRADING}))")
    end


    if params[:status] == 'todos_egresados' then
      @students = @students.where("status IN (#{Student::GRADUATED}, #{Student::FINISH})")
    end

    if params[:status] == 'egresados_graduados' then
      @students = @students.where("status = #{Student::GRADUATED}")
    end

    if params[:status] == 'egresados_no_graduados' then
      @students = @students.where("status = #{Student::FINISH}")
    end

    if params[:status] == 'baja_temporal' then
      @students = @students.where("status = #{Student::INACTIVE}")
    end

    if params[:status] == 'baja_definitiva' then
      @students = @students.where("status = #{Student::UNREGISTERED}")
    end


    if !params[:q].blank?
      @students = @students.where("(CONCAT(first_name,' ',last_name) LIKE :n OR card LIKE :n)", {:n => "%#{params[:q]}%"}) 
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
          if s.status == Student::GRADUATED || s.status == Student::FINISH
            end_date =  Date.strptime(s.thesis.defence_date.strftime("%m/%d/%Y"), "%m/%d/%Y") rescue ''
            
            if end_date.blank? 
              months = ''
            else
              months = months_between(s.start_date,end_date)
            end
          else
            end_date = ''
          end

          
          rows << {'Matricula' => s.card,
                   'Nombre' => s.first_name, 
                   'Apellidos' => s.last_name, 
                   'Estado' => s.status_type,
	           "Fecha_Nac" => s.date_of_birth,
	           "Ciudad_Nac" => s.city,
	           "Estado_Nac" => (s.state.name rescue ''),
	           "Pais_Nac" => (s.country.name rescue ''),
                   "Institucion_Anterior" => (Institution.find(s.previous_institution).full_name rescue ''),
	           "Campus" => (s.campus.name rescue ''),
                   'Programa' => s.program.name,
                   'Inicio' => s.start_date,
                   'Fin' => end_date,
                   'Meses' => months,
                   'Asesor' => (Staff.find(s.supervisor).full_name rescue ''),
                   'Coasesor' => (Staff.find(s.co_supervisor).full_name rescue ''),
                   'Tesis' => s.thesis.title,
                   'Sinodal1' => (Staff.find(s.thesis.examiner1).full_name rescue ''),
                   'Sinodal2' => (Staff.find(s.thesis.examiner2).full_name rescue ''),
                   'Sinodal3' => (Staff.find(s.thesis.examiner3).full_name rescue ''),
                   'Sinodal4' => (Staff.find(s.thesis.examiner4).full_name rescue ''),
                   'Sinodal5' => (Staff.find(s.thesis.examiner5).full_name rescue ''),
                   }
        end
        column_order = ["Matricula", "Nombre", "Apellidos", "Estado", "Fecha_Nac", "Ciudad_Nac", "Estado_Nac", "Pais_Nac", "Institucion_Anterior", "Campus", "Programa", "Inicio", "Fin", "Meses", "Asesor", "Coasesor", "Tesis", "Sinodal1", "Sinodal2", "Sinodal3", "Sinodal4", "Sinodal5"]
        to_excel(rows, column_order, "Estudiantes", "Estudiantes")
      end
    end
  end

  def show
    @student = Student.includes(:program, :thesis, :contact, :scholarship, :advance).find(params[:id])
    @staffs = Staff.order('first_name').includes(:institution)
    @countries = Country.order('name')
    @institutions = Institution.order('name')
    @states = State.order('code')  
    today = Date.today
    yyyy  = today.year - @student.start_date.year
    m = today.month - @student.start_date.month
    
    if m > 0
      @year  = yyyy
      @month = m
    else 
      @year  = yyyy - 1
      @month = 12 + m  
    end

    if @year == 1
      @text_year = " año"
    else
      @text_year = " años"
    end 
   
    if @month == 1
      @text_month = "mes"
    else
      @text_month = "meses"
    end 


    if current_user.access == User::OPERATOR
      @campus = Campus.order('name').where(:id=> current_user.campus_id)
    else    
      @campus = Campus.order('name')
    end 
    render :layout => false
  end

  def new
    @student = Student.new
    @programs = Program.order('name')
    render :layout => false
  end

  def create
    flash = {}
    @student = Student.new(params[:student])

    if @student.save
      flash[:notice] = "Estudiante creado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Create Student: #{@student.id},#{@student.first_name} #{@student.last_name}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @student.card
            render :json => json
          else 
            redirect_to @student
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
            json[:errors] = @student.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @student
          end
        end
      end
    end
  end

  def update 
    flash = {}
    @student = Student.find(params[:id])

    if @student.update_attributes(params[:student])
      flash[:notice] = "Estudiante actualizado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Student: #{@student.id},#{@student.first_name} #{@student.last_name}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:thesis_status] = @student.thesis.status
            render :json => json
          else 
            redirect_to @student
          end
        end
      end
    else
      flash[:error] = "Error al actualizar al estudiante."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @student.errors
            json[:errors_full] = @student.errors.full_messages
            render :json => json, :status => :unprocessable_entity
          else 
            redirect_to @student
          end
        end
      end
    end
  end

  def change_image
    @student = Student.find(params[:id])
    render :layout => 'standalone'
  end

  def upload_image
    flash = {}
    @student = Student.find(params[:id])
    if @student.update_attributes(params[:student])
      flash[:notice] = "Imagen actualizada."
    else
      flash[:error] = "Error al actualizar la imagen."
    end

    redirect_to :action => 'change_image', :id => params[:id]
  end

  def files
    @student = Student.includes(:student_file).find(params[:id])
    @student_file = StudentFile.new
    render :layout => 'standalone'
  end

  def upload_file
    flash = {}
    params[:student_file]['file'].each do |f|
      @student_file = StudentFile.new
      @student_file.student_id = params[:student_file]['student_id']
      @student_file.file = f
      @student_file.description = f.original_filename
      if @student_file.save
        flash[:notice] = "Archivo subido exitosamente."
      else
        flash[:error] = "Error al subir archivo."
      end
    end

    redirect_to :action => 'files', :id => params[:id]
  end

  def file
    s = Student.find(params[:id])
    sf = s.student_file.find(params[:file_id]).file
    send_file sf.to_s, :x_sendfile=>true
  end 

  def delete_file
  end

  def new_advance
    @student = Student.find(params[:id])
    @staffs = Staff.order('first_name')
    render :layout => 'standalone'
  end

  def create_advance
    flash = {}
    @student = Student.find(params[:student_id])
    if @student.update_attributes(params[:student])
      flash[:notice] = "Nuevo avance creado."
    else
      flash[:error] = "Error al crear avance."
    end
    render :layout => 'standalone'
  end

  def assign_thesis_number
    flash = {}
    @student = Student.find(params[:student_id])
    @student.thesis.set_number
    if @student.save
      flash[:notice] = "Numero de tesis asignado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Thesis Number asigned to Student: #{@student.id},#{@student.first_name} #{@student.last_name}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:number] = @student.thesis.number
            render :json => json
          else
            redirect_to @student
          end
        end
      end
    else
      flash[:error] = "Error al asignar el numero de tesis."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @student.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @student
          end
        end
      end
    end
  end

  def schedule_table
    @is_pdf = false
    @ts = TermStudent.where(:student_id => params[:id], :term_id => params[:term_id]).first
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
    @ts.term_course_student.where(:status => TermCourseStudent::ACTIVE).each do |c|
      c.term_course.term_course_schedules.where(:status => TermCourseSchedule::ACTIVE).each do |session_item|
        hstart = session_item.start_hour.hour
        hend = session_item.end_hour.hour - 1
        (hstart..hend).each do |h|
           if courses[c.term_course.course.id].nil? 
             n += 1
             courses[c.term_course.course.id] = n
           end
           comments = ''
           if session_item.start_date != @ts.term.start_date
             comments += "Inicia: #{l session_item.start_date, :format => :long}\n"
           end
           if session_item.end_date != @ts.term.end_date
             comments += "Finaliza: #{l session_item.end_date, :format => :long}"
           end
           
           staff_name = session_item.staff.full_name rescue 'Sin docente'

           details = {
             "name" => c.term_course.course.name, 
             "staff_name" => staff_name,
             "comments" => comments,
             "id" => session_item.id, 
             "n" => courses[c.term_course.course.id]
           }
           @schedule[h][session_item.day] << details
           @min_hour = h if h < @min_hour
           @max_hour = h if h > @max_hour
        end
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
        filename = "horario-#{@ts.student_id}-#{@ts.term_id}.pdf"
        send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        return # to avoid double render call
      end
    end
  end

  def term_grades
    @is_pdf = false
    @student = Student.includes(:program, :thesis, :contact, :scholarship, :advance).find(params[:id])
    @ts = TermStudent.where(:student_id => params[:id], :term_id => params[:term_id]).first
    @grades = TermStudent.find_by_sql(["SELECT courses.code, courses.name, grade FROM term_students INNER JOIN term_course_students ON term_students.id = term_course_students.term_student_id  INNER JOIN term_courses ON term_course_id = term_courses.id INNER JOIN courses ON courses.id = term_courses.course_id WHERE term_students.student_id = :student_id AND term_students.term_id = :term_id AND term_course_students.status = :status ORDER BY courses.name", {:student_id => params[:id], :term_id => params[:term_id], :status => TermCourseStudent::ACTIVE}])
    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.pdf do
        institution = Institution.find(1)
        @logo = institution.image_url(:medium).to_s
        @is_pdf = true
        html = render_to_string(:layout => false , :action => "term_grades.html.haml")
        kit = PDFKit.new(html, :page_size => 'Letter')
        kit.stylesheets << "#{Rails.root}#{Sapos::Application::ASSETS_PATH}pdf.css"
        filename = "boleta-#{@ts.student_id}-#{@ts.term_id}.pdf"
        send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        return # to avoid double render call
      end
    end
  end

  def term_grades_list
    @tcs = TermCourseSchedule.where("start_date>=CURDATE() AND start_date<=DATE_ADD(CURDATE(),INTERVAL 30 DAY)").order("start_date, start_hour")
    render :layout => false
  end
  
  def advances_list
    if current_user.access == User::ADMINISTRATOR
      @advances = Advance.where("advance_date>=CURDATE() AND advance_date<=DATE_ADD(CURDATE(),INTERVAL 30 DAY)")
    elsif  current_user.access == User::OPERATOR
      @advances = Advance.joins(:student).where("advance_date>=CURDATE() AND advance_date<=DATE_ADD(CURDATE(),INTERVAL 30 DAY) AND campus_id=:campus_id",{:campus_id=>current_user.campus_id})
    end 
    render :layout => false
  end

  def id_card
    @student = Student.find(params[:id])
    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.pdf do
        institution = Institution.find(1)
        @logo = institution.image_url(:medium).to_s
        @is_pdf = true
        html = render_to_string(:layout => false , :template => "students/id_card.html.haml", :formats => [:html], :handlers => [:haml])
        kit = PDFKit.new(html, :page_size => 'Legal', :orientation => 'Landscape', :margin_top    => '0',:margin_right  => '0', :margin_bottom => '0', :margin_left   => '0')
        kit.stylesheets << "#{Rails.root}#{Sapos::Application::ASSETS_PATH}card.css"
        filename = "ID-#{@student.card}.pdf"
        send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        return # to avoid double render call
      end
    end
  end

  def kardex 
    @student = Student.includes(:program, :thesis, :contact, :scholarship, :advance).find(params[:id])
    	
    respond_with do |format|
      format.html do
        render :layout => false
      end 
      format.pdf do
        institution = Institution.find(1)
        @logo = institution.image_url(:medium).to_s
        @is_pdf = true
        html = render_to_string(:layout => false , :template => "students/_kardex.html.haml", :formats => [:html], :handlers => [:haml])
        kit = PDFKit.new(html, :page_size => 'Letter')
        kit.stylesheets << "#{Rails.root}#{Sapos::Application::ASSETS_PATH}pdf.css"
        filename = "kardex-#{@student.id}.pdf"
        send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        return # to avoid double render call
      end
    end
  end

  def months_between(past_date,recent_date)
    total_years = (recent_date.year - past_date.year)

    if total_years > 0
      rdm   = recent_date.month - 12    
      pdm   = past_date.month - 12

      ((rdm - pdm) + 12 * total_years)
    else
      (recent_date.month - past_date.month)
    end
  end 
end
