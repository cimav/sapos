# coding: utf-8
class StudentsController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
    @remote_id = params[:student_id]
    
    if current_user.campus_id == 0
      @campus     = Campus.order('name')
      @all_campus = 1 
    else
      @campus = Campus.joins(:user).where(:users=>{:id=>current_user.id})
      @all_campus = 0
    end 
    
    if current_user.program_type == Program::ALL
      @programs     = Program.order('name')
      @program_type = Program::PROGRAM_TYPE.invert.sort {|a,b| a[1] <=> b[1] }
    else
      @programs     = Program.joins(:permission_user).where(:permission_users=>{:user_id=>current_user.id}).order('name')
      @program_type = { Program::PROGRAM_TYPE[current_user.program_type] => current_user.program_type }
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
      if params[:q].to_i != 0
        @students = @students.where("id = ?",params[:q].to_i)
      else
        @students = @students.where("(CONCAT(first_name,' ',last_name) LIKE :n OR card LIKE :n)", {:n => "%#{params[:q]}%"}) 
      end
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
    
    # Descartamos los que tienen status de borrado
    #@students = @students.where("status<>0")

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
    @applicant_id = 0
    @applicants   = Applicant.where(:student_id=>@student.id,:campus_id=>@student.campus_id,:program_id=>@student.program_id)

    if @applicants.size>0
      @applicant_id = @applicants[0].id
    end

    @staffs = Staff.order('first_name').includes(:institution)
    @countries = Country.order('name')
    @institutions = Institution.order('name')
    @states = State.order('code')  
    @status = Student::STATUS
    
    if @student.thesis.status.eql? "C"
      today = @student.thesis.defence_date
    else
      today = Date.today
    end 

    yyyy  = today.year - @student.start_date.year
    m = today.month - @student.start_date.month
    
    if m >= 0
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
 
    if current_user.access != User::MANAGER
      my_hash = params[:student]
      status = my_hash[:status]
      if (status.to_i==Student::GRADUATED or status.to_i==Student::UNREGISTERED or status.to_i==Student::INACTIVE) and (status.to_i != @student.status.to_i)
	flash[:error] = "El estatus \"#{Student::STATUS[status.to_i]}\" solo lo puede establecer el Jefe de Posgrado"
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
	return false
      end 
    end
    
    if @student.update_attributes(params[:student])
      graduated = 0
      if (@student.status.to_i==Student::GRADUATED and @student.graduate.nil?)
	graduated = 1
      end
      flash[:notice] = "Estudiante actualizado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Student: #{@student.id},#{@student.first_name} #{@student.last_name}"}).save
      respond_with do |format|
	format.html do
	  if request.xhr?
	    json = {}
	    json[:flash] = flash
	    json[:graduated] = graduated 
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

  def destroy
    parameters= {}
    time = Time.now

    @student.deleted = 1
    @student.deleted_at = time

    if @student.save
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Delete Student: #{@student.id},#{@student.first_name} #{@student.last_name}"}).save
      @message = "Alumno Eliminado"
      render_message @student, @message, parameters
    else
      @message = "Error al eliminar el alumno"
      render_error @student,@message, parameters
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
             "classroom" => session_item.classroom.name,
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

  def certificates
    @student = Student.includes(:program, :thesis, :contact, :scholarship, :advance).find(params[:id])
    time = Time.new
    year = time.year.to_s
    head = File.read("#{Rails.root}/app/views/students/certificates/head.html")
    base = File.read("#{Rails.root}/app/views/students/certificates/base.html")
    if current_user.campus_id == 2
      @firma  = "Alejandra García García"
      @puesto = "Coordinador Académico Unidad Monterrey"
    else
      @firma  = "M.H. Nicté Ortiz Villanueva"
      @puesto = "Jefa del Departamento de Posgrado"
    end 

    if params[:type] == "estudios"
      @consecutivo = get_consecutive(@student, time, Certificate::STUDIES)
      @rails_root  = "#{Rails.root}"
      @year_s      = year[2,4]
      @year        = year
      @days        = time.day.to_s
      @month       = get_month_name(time.month)
      @nombre      = @student.full_name
      @matricula   = @student.card
      @programa    = @student.program.name
      
      if @student.gender == 'F'
        @genero  = "a"
        @genero2 = "la"
      elsif @student.gender == 'H'
        @genero  = "o"
        @genero2 = "el"
      else
        @genero  = "x"
        @genero2 = "x"
      end
      
      html = render_to_string(:layout => 'certificate' , :template=> 'students/certificates/constancia_estudios')
      kit = PDFKit.new(html, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
      filename = "constancia-estudios-#{@student.id}.pdf"
      send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
      return # to avoid double render call
    end 

    if params[:type] == "inscripcion"
      string = File.read("#{Rails.root}/app/views/students/certificates/constancia_inscripcion.html")
      string = "#{head}#{string}#{base}"
      consecutive = get_consecutive(@student, time, Certificate::ENROLLMENT)
      s1 = string.gsub("<nombre>",@student.full_name)
      s1 = s1.gsub("<programa>",@student.program.name)
      s1 = s1.gsub("<matricula>",@student.card)
      s1 = s1.gsub("<asesor>",Staff.find(@student.supervisor).full_name)
      s1 = s1.gsub("<rails_root>","#{Rails.root}")
      s1 = s1.gsub("<consecutivo>",consecutive)
      s1 = s1.gsub("<year_s>",year[2,4])
      s1 = s1.gsub("<year>",year)
      s1 = s1.gsub("<days>",time.day.to_s)
      s1 = s1.gsub("<month>",get_month_name(time.month))
      s1 = s1.gsub("<start_month>",get_month_name(@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.start_date.month).capitalize)
      s1 = s1.gsub("<end_month>",get_month_name(@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.end_date.month).capitalize)
      s1 = s1.gsub("<end_year>",@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.end_date.year.to_s)
      if @student.gender == 'F'
	s1 = s1.gsub("<genero>","a")
      elsif @student.gender == 'H'
	s1 = s1.gsub("<genero>","o")
      else
	s1 = s1.gsub("<genero>","x")
      end
      s1 = s1.gsub("<firma>",@firma)
      s1 = s1.gsub("<puesto>",@puesto)
      kit = PDFKit.new(s1, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
      filename = "constancia-inscripcion-#{@student.id}.pdf"
      send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
      return
    end 

    if params[:type] == "visa"
      @consecutivo = get_consecutive(@student, time, Certificate::VISA)
      @rails_root  = "#{Rails.root}"
      @year_s      = year[2,4]
      @year        = year
      @days        = time.day.to_s
      @month       = get_month_name(time.month)
      @nombre      = @student.full_name
      @matricula   = @student.card
      @asesor      = Staff.find(@student.supervisor).full_name
      @programa    = @student.program.name
      @student_image_uri = @student.image_url.to_s
	      
      scholarship = @student.scholarship.where("scholarships.status = 'ACTIVA' AND scholarships.start_date<=CURDATE() AND scholarships.end_date>=CURDATE()")
 
      if @student.gender == 'F'
        @genero  = "a"
        @genero2 = "la"
      elsif @student.gender == 'H'
        @genero  = "o"
        @genero2 = "el"
      else
        @genero  = "x"
        @genero2 = "x"
      end

      @scholarship = @student.scholarship.joins(:scholarship_type=>[:scholarship_category]).where("scholarships.status = 'ACTIVA' AND scholarships.start_date<=CURDATE() AND scholarships.end_date>=CURDATE() AND scholarship_categories.id=1")

      html = render_to_string(:layout => 'certificate' , :template=> 'students/certificates/constancia_visa')
      kit = PDFKit.new(html, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
      filename = "constancia-visa-#{@student.id}.pdf"
      send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
      return # to avoid double render call
    end
    
    if params[:type] == "promedio"
      string = File.read("#{Rails.root}/app/views/students/certificates/constancia_promedio_general.html")
      string = "#{head}#{string}#{base}"
      consecutive = get_consecutive(@student, time, Certificate::AVERAGE)
      s1 = string.gsub("<rails_root>","#{Rails.root}")
      s1 = s1.gsub("<consecutivo>",consecutive)
      s1 = s1.gsub("<year_s>",year[2,4])
      s1 = s1.gsub("<year>",year)
      s1 = s1.gsub("<days>",time.day.to_s)
      s1 = s1.gsub("<month>",get_month_name(time.month))
      s1 = s1.gsub("<nombre>",@student.full_name)
      s1 = s1.gsub("<matricula>",@student.card)
      s1 = s1.gsub("<asesor>",Staff.find(@student.supervisor).full_name)
      s1 = s1.gsub("<programa>",@student.program.name)
      ######################################################################
      s1 = s1.gsub("<semestre>",@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.code)
      s1 = s1.gsub("<firma>",@firma)
      s1 = s1.gsub("<puesto>",@puesto)
      counter = 0
      counter_grade = 0
      sum = 0
      avg = 0
      @student.term_students.each do |te|
        te.term_course_student.where(:status => TermCourseStudent::ACTIVE).each do |tcs|
          counter += 1
          if !(tcs.grade.nil?)
            if !(tcs.grade<70)
              counter_grade += 1
              sum = sum + tcs.grade
            end 
          end 
        end 
      end 
    
      if counter > 0 
        avg = (sum / (counter_grade * 1.0)).round(2) if counter_grade > 0 
      end 
      s1 = s1.gsub("<promedio>", avg.to_s)
      if @student.gender == 'F'
        s1 = s1.gsub("<genero>","a")
        s1 = s1.gsub("<genero2>","la")
      elsif @student.gender == 'H'
        s1 = s1.gsub("<genero>","o")
        s1 = s1.gsub("<genero2>","el")
      else
        s1 = s1.gsub("<genero>","x")
        s1 = s1.gsub("<genero2>","x")
      end
      ######################################################################
      kit = PDFKit.new(s1, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
      filename = "constancia-inscripcion-#{@student.id}.pdf"
      send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
      return 
    end
    
    if params[:type] == "semestral"
      string = File.read("#{Rails.root}/app/views/students/certificates/constancia_promedio_semestral.html")
      string = "#{head}#{string}#{base}"
      consecutive = get_consecutive(@student, time, Certificate::SEMESTER_AVERAGE)
      s1 = string.gsub("<rails_root>","#{Rails.root}")
      s1 = s1.gsub("<consecutivo>",consecutive)
      s1 = s1.gsub("<year_s>",year[2,4])
      s1 = s1.gsub("<year>",year)
      s1 = s1.gsub("<days>",time.day.to_s)
      s1 = s1.gsub("<month>",get_month_name(time.month))
      s1 = s1.gsub("<nombre>",@student.full_name)
      s1 = s1.gsub("<matricula>",@student.card)
      s1 = s1.gsub("<asesor>",Staff.find(@student.supervisor).full_name)
      s1 = s1.gsub("<programa>",@student.program.name)
      s1 = s1.gsub("<firma>",@firma)
      s1 = s1.gsub("<puesto>",@puesto)
      ######################################################################
      ts = @student.term_students.joins(:term).order("terms.start_date")
      term = ts.last.term
      s1 = s1.gsub("<semestre>",term.code)
      avg = get_semester_average(term)

      if avg.eql? 0
        term = ts[ts.size - 2].term
        avg = get_semester_average(term)
      end
      
      s1 = s1.gsub("<promedio>", avg.to_s)
      s1 = s1.gsub("<semestre_cursado>",term.code)
      if @student.gender == 'F'
        s1 = s1.gsub("<genero>","a")
        s1 = s1.gsub("<genero2>","la")
      elsif @student.gender == 'H'
        s1 = s1.gsub("<genero>","o")
        s1 = s1.gsub("<genero2>","el")
      else
        s1 = s1.gsub("<genero>","x")
        s1 = s1.gsub("<genero2>","x")
      end
      ######################################################################
      kit = PDFKit.new(s1, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
      filename = "constancia-inscripcion-#{@student.id}.pdf"
      send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
      return 
    end
    
    if params[:type] == "seguro"
      string = File.read("#{Rails.root}/app/views/students/certificates/constancia_tramite_seguro.html")
      string = "#{head}#{string}#{base}"
      consecutive = get_consecutive(@student, time, Certificate::SOCIAL_WELFARE)
      s1 = string.gsub("<rails_root>","#{Rails.root}")
      s1 = s1.gsub("<consecutivo>",consecutive)
      s1 = s1.gsub("<year_s>",year[2,4])
      s1 = s1.gsub("<year>",year)
      s1 = s1.gsub("<days>",time.day.to_s)
      s1 = s1.gsub("<month>",get_month_name(time.month))
      s1 = s1.gsub("<nombre>",@student.full_name)
      s1 = s1.gsub("<matricula>",@student.card)
      s1 = s1.gsub("<asesor>",Staff.find(@student.supervisor).full_name)
      s1 = s1.gsub("<programa>",@student.program.name)
      ######################################################################
      s1 = s1.gsub("<start_day>",@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.start_date.day.to_s)
      s1 = s1.gsub("<end_day>",@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.end_date.day.to_s)
      s1 = s1.gsub("<start_month>",get_month_name(@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.start_date.month).capitalize)
      s1 = s1.gsub("<end_month>",get_month_name(@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.end_date.month).capitalize)
      s1 = s1.gsub("<end_year>",@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.end_date.year.to_s)
      
      s1 = s1.gsub("<creditos>", get_credits(@student))
      s1 = s1.gsub("<promedio>",get_average(@student))
      s1 = s1.gsub("<firma>",@firma)
      s1 = s1.gsub("<puesto>",@puesto)
      result = @student.scholarship.where("scholarships.status = 'ACTIVA' AND scholarships.start_date<=CURDATE() AND scholarships.end_date>=CURDATE()")
      
      if result.size.eql? 0
        s1 = s1.gsub(/<beca>.+<\/beca>/m,"")
      else
        s1 = s1.gsub(/<total_beca>/,result[0].amount.to_s)
      end
      s1 = s1.gsub("<semester>",get_semester(@student))
      if @student.gender == 'F'
        s1 = s1.gsub("<genero>","a")
        s1 = s1.gsub("<genero2>","la")
      elsif @student.gender == 'H'
        s1 = s1.gsub("<genero>","o")
        s1 = s1.gsub("<genero2>","el")
      else
        s1 = s1.gsub("<genero>","x")
        s1 = s1.gsub("<genero2>","x")
      end
      ######################################################################
      kit = PDFKit.new(s1, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
      filename = "constancia-inscripcion-#{@student.id}.pdf"
      send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
      return 
    end

    if params[:type] == "creditos"
      string = File.read("#{Rails.root}/app/views/students/certificates/constancia_creditos_cubiertos.html")
      string = "#{head}#{string}#{base}"
      consecutive = get_consecutive(@student, time, Certificate::CREDITS)
      s1 = string.gsub("<rails_root>","#{Rails.root}")
      s1 = s1.gsub("<consecutivo>",consecutive)
      s1 = s1.gsub("<year_s>",year[2,4])
      s1 = s1.gsub("<year>",year)
      s1 = s1.gsub("<days>",time.day.to_s)
      s1 = s1.gsub("<month>",get_month_name(time.month))
      s1 = s1.gsub("<nombre>",@student.full_name)
      s1 = s1.gsub("<matricula>",@student.card)
      s1 = s1.gsub("<asesor>",Staff.find(@student.supervisor).full_name)
      s1 = s1.gsub("<programa>",@student.program.name)
      ######################################################################
      s1 = s1.gsub("<creditos>", get_credits(@student))
      s1 = s1.gsub("<promedio>",get_average(@student))
      if @student.gender == 'F'
        s1 = s1.gsub("<genero>","a")
        s1 = s1.gsub("<genero2>","la")
      elsif @student.gender == 'H'
        s1 = s1.gsub("<genero>","o")
        s1 = s1.gsub("<genero2>","el")
      else
        s1 = s1.gsub("<genero>","x")
        s1 = s1.gsub("<genero2>","x")
      end
      
      if @student.program.level.eql? "1"
        s1 = s1.gsub("<creditos_totales>","75.0")
        s1 = s1.gsub("<nivel>","de la Maestría")
      elsif @student.program.level.eql? "2"
        s1 = s1.gsub("<creditos_totales>","150.0")
        s1 = s1.gsub("<nivel>","del Doctorado")
      else
        s1 = s1.gsub("<creditos_totales>","Unknown")
        s1 = s1.gsub("<nivel>","Unknown")
      end
      s1 = s1.gsub("<firma>",@firma)
      s1 = s1.gsub("<puesto>",@puesto)
      ######################################################################
      kit = PDFKit.new(s1, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
      filename = "constancia-inscripcion-#{@student.id}.pdf"
      send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
      return 
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

  def get_month_name(number)
    months = ["enero","febrero","marzo","abril","mayo","junio","julio","agosto","septiembre","octubre","noviembre","diciembre"]
    name = months[number - 1]
    return name
  end

  def get_cardinal_name(number)
    cardinals = [
      "cero",
      "uno",
      "dos",
      "tres",
      "cuatro",
      "cinco",
      "seis",
      "siete",
      "ocho",
      "nueve",
      "diez",
      "once",
      "doce",
      "trece",
      "catorce",
      "quince",
      "dieciséis",
      "diecisiete",
      "dieciocho",
      "diecinueve",
      "veinte",
      "veintiuno",
      "veintidós",
      "veintitrés",
      "veinticuatro",
      "veinticinco",
      "veintiseis",
      "veintisiete",
      "veintiocho",
      "veintinueve",
      "treinta",
      "treinta y uno",
      "treinta y dos",
      "treinta y tres",
      "treinta y cuatro",
      "treinta y cinco",
      "treinta y seis",
      "treinta y siete",
      "treinta y ocho",
      "treinta y nueve",
      "cuarenta",
      "cuarenta y uno",
      "cuarenta y dos",
      "cuarenta y tres",
      "cuarenta y cuatro",
      "cuarenta y cinco",
      "cuarenta y seis",
      "cuarenta y siete",
      "cuarenta y ocho",
      "cuarenta y nueve",
      "cincuenta",
      "cincuenta y uno",
      "cincuenta y dos",
      "cincuenta y tres",
      "cincuenta y cuatro",
      "cincuenta y cinco",
      "cincuenta y seis",
      "cincuenta y siete",
      "cincuenta y ocho",
      "cincuenta y nueve",
      "sesenta",
      "sesenta y uno",
      "sesenta y dos",
      "sesenta y tres",
      "sesenta y cuatro",
      "sesenta y cinco",
      "sesenta y seis",
      "sesenta y siete",
      "sesenta y ocho",
      "sesenta y nueve",
      "setenta",
      "setenta y uno",
      "setenta y dos",
      "setenta y tres",
      "setenta y cuatro",
      "setenta y cinco",
      "setenta y seis",
      "setenta y siete",
      "setenta y ocho",
      "setenta y nueve",
      "ochenta",
      "ochenta y uno",
      "ochenta y dos",
      "ochenta y tres",
      "ochenta y cuatro",
      "ochenta y cinco",
      "ochenta y seis",
      "ochenta y siete",
      "ochenta y ocho",
      "ochenta y nueve",
      "noventa",
      "noventa y uno",
      "noventa y dos",
      "noventa y tres",
      "noventa y cuatro",
      "noventa y cinco",
      "noventa y seis",
      "noventa y siete",
      "noventa y ocho",
      "noventa y nueve",
      "cien"]
    
    name = cardinals[number]
    return name
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
  
  def get_average(student)
    counter = 0
    counter_grade = 0
    sum = 0
    avg = 0
    student.term_students.each do |te|
      te.term_course_student.where(:status => TermCourseStudent::ACTIVE).each do |tcs|
        counter += 1
        if !(tcs.grade.nil?)
          if !(tcs.grade<70)
            counter_grade += 1
            sum = sum + tcs.grade
          end
        end
      end
    end

    if counter > 0
      avg = (sum / (counter_grade * 1.0)).round(2) if counter_grade > 0
    end
    
    return avg.to_s
  end

  def get_credits(student)
    credits = 0
    student.term_students.each do |te|
      te.term_course_student.where(:status => TermCourseStudent::ACTIVE).each do |tcs|
        if !(tcs.grade.nil?)
          if !(tcs.grade<70)
            credits = credits + tcs.term_course.course.credits
          end
        end
      end
    end
    
    return credits.to_s
  end

  def get_semester(student)
    semester = get_semester_text(student.term_students.size)
    return semester
  end

  def get_semester_text(total)
   semester_text = case total
     when 1 then "primer" 
     when 2 then "segundo"
     when 3 then "tercero"
     when 4 then "cuarto"
     when 5 then "quinto"
     when 6 then "sexto"
     when 7 then "septimo"
     when 8 then "octavo"
     when 9 then "noveno"
     when 10 then "decimo"
     else "desconocido"
   end
   
    return semester_text
  end

  def get_semester_average(term)
    counter = 0
    counter_grade = 0
    sum = 0
    avg = 0
    @student.term_students.where(:term_id=>term.id).each do |te|
      te.term_course_student.where(:status => TermCourseStudent::ACTIVE).each do |tcs|
        counter += 1
        if !(tcs.grade.nil?)
          if !(tcs.grade<70)
            counter_grade += 1
            sum = sum + tcs.grade
          end 
        end 
      end 
    end 
  
    if counter > 0 
      avg = (sum / (counter_grade * 1.0)).round(2) if counter_grade > 0 
    end 
    return avg
  end

  def sinodal_certificates
    @student = Student.includes(:program, :thesis, :contact, :scholarship, :advance).find(params[:student_id])

    time = Time.new
    year = time.year.to_s
    head = File.read("#{Rails.root}/app/views/students/certificates/head.html")
    base = File.read("#{Rails.root}/app/views/students/certificates/base.html")
    
    if current_user.campus_id == 2
      @firma  = "Alejandra García García"
      @puesto = "Coordinador Académico Unidad Monterrey"
    else
      @firma  = "M.H. Nicté Ortiz Villanueva"
      @puesto = "Jefa del Departamento de Posgrado"
    end 

    @consecutivo = get_consecutive(@student, time, Certificate::EXAMINER)
    @rails_root  = "#{Rails.root}"
    @year_s      = year[2,4]
    @year        = year
    @days        = time.day.to_s
    @month       = get_month_name(time.month)
    @nombre      = @student.full_name
    @matricula   = @student.card
    @programa    = @student.program.name
    @asesor      = Staff.find(params[:staff_id]).full_name
    @institution = Staff.find(params[:staff_id]).institution.name
    @thesis_title= @student.thesis.title
	      
    scholarship = @student.scholarship.where("status = 'ACTIVA' AND start_date<=CURDATE() AND end_date>=CURDATE()")
 
    if @student.gender == 'F'
      @genero  = "a"
      @genero2 = "la"
    elsif @student.gender == 'H'
      @genero  = "o"
      @genero2 = "el"
    else
      @genero  = "x"
      @genero2 = "x"
    end

    @scholarship = @student.scholarship.joins(:scholarship_type=>[:scholarship_category]).where("status = 'ACTIVA' AND start_date<=CURDATE() AND end_date>=CURDATE() AND scholarship_categories.id=1")

    html = render_to_string(:layout => 'certificate' , :template=> 'students/certificates/constancia_sinodal_externo')
    kit = PDFKit.new(html, :page_size => 'Letter', :margin_top => '0.1in', :margin_right => '0.1in', :margin_left => '0.1in', :margin_bottom => '0.1in')
    filename = "constancia-sinodal-externo-#{@student.id}.pdf"
    send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
    return # to avoid double render call
  end

  def grade_certificates
    @r_root    = Rails.root.to_s
    @time      = Time.now
    @thesis    = Thesis.find(params[:thesis_id])
    @level     = @thesis.student.program.level
    @examiner1 = Staff.find(@thesis.examiner1).full_name rescue ""
    @examiner2 = Staff.find(@thesis.examiner2).full_name rescue ""
    @examiner3 = Staff.find(@thesis.examiner3).full_name rescue ""
    @examiner4 = Staff.find(@thesis.examiner4).full_name rescue "" 
    @examiner5 = Staff.find(@thesis.examiner5).full_name rescue ""
    
    @examiner1t = Staff.find(@thesis.examiner1).title rescue ""
    @examiner2t = Staff.find(@thesis.examiner2).title rescue ""
    @examiner3t = Staff.find(@thesis.examiner3).title rescue ""
    @examiner4t = Staff.find(@thesis.examiner4).title rescue "" 
    @examiner5t = Staff.find(@thesis.examiner5).title rescue ""

    filename = "#{@r_root}/private/prawn_templates/acta_de_grado.pdf"
    Prawn::Document.generate("full_template.pdf", :template => filename) do |pdf|
      pdf.font_families.update("Arial" => {
        :bold        => "#{@r_root}/private/fonts/arial/arialbd.ttf",
        :italic      => "#{@r_root}/private/fonts/arial/ariali.ttf",
        :bold_italic => "#{@r_root}/private/fonts/arial/arialbi.ttf",
        :normal      => "#{@r_root}/private/fonts/arial/arial.ttf"
      })
      pdf.font "Arial"

      pdf.image "#{@r_root}/private/cimav_sc.png", :at => [112,703], :height => 48 

      # SET HOUR AND DAY
      @hora = "%02d:%02d HORAS DEL DÍA %2d" % [@time.hour,@time.min,@time.day]
      x = 388
      y = 629
      w = 150
      h = 11 
      size = 10
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [388,630], 130, 10
      pdf.fill_color "373435"
      pdf.text_box @hora , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :left, :valign=> :center

      # SET MONTH AND YEAR
      month = get_month_name(@time.month)
      year = @time.year
      @m_y = "MES DE #{month.upcase} DEL #{year}. SE REUNIERON LOS"
      x = 244
      y = 618
      w = 450
      h = 11 
      size = 10
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [244,620], 330, 11
      pdf.fill_color "373435"
      pdf.text_box @m_y , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :left, :valign=> :center
      
       
      # SET  THESIS EXAMINERS
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [246,586], 100, 11
      pdf.fill_color "373435"
      text = "#{@examiner1t.mb_chars.upcase} #{@examiner1.mb_chars.upcase}"

      pdf.draw_text text, :at=>[246,576], :size=>11
      
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [245,574], 100, 11
      pdf.fill_color "373435"
      text = "#{@examiner2t.mb_chars.upcase} #{@examiner2.mb_chars.upcase}"
      
      pdf.draw_text text, :at=>[246,564], :size=>11
      
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [245,562], 100, 11
      pdf.fill_color "373435"
      text = "#{@examiner3t.mb_chars.upcase} #{@examiner3.mb_chars.upcase}"
      
      pdf.draw_text text, :at=>[246,552], :size=>11
      
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [245,550], 100, 11
      pdf.fill_color "373435"
      text = "#{@examiner4t.mb_chars.upcase} #{@examiner4.mb_chars.upcase}"
      
      pdf.draw_text @examiner4.mb_chars.upcase, :at=>[246,540], :size=>11
      
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [245,538], 100, 11
      pdf.fill_color "373435"
      text = "#{@examiner5t.mb_chars.upcase} #{@examiner5.mb_chars.upcase}"
      
      pdf.draw_text @examiner5.mb_chars.upcase, :at=>[246,528], :size=>11
      
      ## SET THESIS TITLE
      x = 155
      y = 490
      w = 400
      h = 40
      size  = 14
      text = @thesis.title
      text = "\"#{text}\""  
      
      if text.size >= 110 && text.size <= 165
        size = 12 
      elsif text.size > 165 && text.size <= 220
        size = 10
      elsif text.size > 220
        size = 9
      end

      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "373435"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=>:bold, :align=> :center, :valign=> :center

      # SET STUDENT NAME
      x = 150
      y = 384
      w = 390
      h = 30
      size = 18
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "373435"
      text = @thesis.student.full_name
      
      if text.size >= 40
        size = 16
      end
      
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=>:bold, :align=> :center, :valign=> :center


      # SET GRADE
      x = 150
      y = 450
      w = 400
      h = 55
      size = 12
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "373435"
      grado = @thesis.student.program.name.mb_chars.upcase
      text = "PARA OBTENER EL GRADO DE #{grado} HABIÉNDOSE CUBIERTO LOS REQUISITOS ESTABLECIDOS EN EL PLAN DE ESTUDIOS VIGENTE, QUE SUSTENTA:" 
      
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center

      # SET PRESIDENT
      x = 5
      y = 225
      w = 225
      h = 15 
      size = 10
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "373435"
      text = "#{@examiner1t.mb_chars.upcase} #{@examiner1.mb_chars.upcase}"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
     
      # SET SECRETARY
      x = 307
      y = 225
      w = 225
      h = 15 
      size = 10
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "373435"
      if  @level=1
        text = "#{@examiner3t.mb_chars.upcase} #{@examiner3.mb_chars.upcase}"
      elsif @level= 2
        text = "#{@examiner5t.mb_chars.upcase} #{@examiner5.mb_chars.upcase}"
      end
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
      
      # SET  THIRD VOCAL
      if @level = 1
        x = 153
        y = 135
        w = 225
        h =  70
        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x,y], w, h
      elsif @level = !
        x = 153
        y = 115
        w = 225
        h = 15 
        size = 10
        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x,y], w, h
        pdf.fill_color "373435"
        text = "#{@examiner4t.mb_chars.upcase} #{@examiner4.mb_chars.upcase}"
        pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
      end
      
      # SET SECOND VOCAL
      if @level = 1
        x = 307
        y = 168
        w = 225
        h = 115 
        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x,y], w, h
      elsif  @level = 2
        x = 307
        y = 158
        w = 225
        h = 15 
        size = 10
        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x,y], w, h
        pdf.fill_color "373435"
        text = "#{@examiner3t.mb_chars.upcase} #{@examiner3.mb_chars.upcase}"
        pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
      end 
      
      # SET FIRST VOCAL
      if @level = 1
        x = 5
        y = 170
        w = 225
        h = 70
        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x,y], w, h
        x = 155 
        y = 154
        w = 225
        h = 15 
        size = 10
        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x,y], w, h
        pdf.fill_color "373435"
        # line
        text = "____________________________________________"
        pdf.text_box text , :at=>[205,164], :width => 150, :height=>10 , :size=>5, :align=> :left, :valign=> :top
        # text
        text = "#{@examiner2t.mb_chars.upcase} #{@examiner2.mb_chars.upcase}"
        pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :top
        text = "1er VOCAL"
        pdf.text_box text , :at=>[x,y - 13], :width => w, :height=> h, :size=>12, :align=> :center, :valign=> :top
       elsif @level = 2
         x = 5
         y = 158
         w = 225
         h = 15 
         size = 10
         pdf.fill_color "ffffff"
         pdf.fill_rectangle [x,y], w, h
         pdf.fill_color "373435"
         text = "#{@examiner2t.mb_chars.upcase} #{@examiner2.mb_chars.upcase}"
         pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
       end

      # RENDER
      send_data pdf.render, type: "application/pdf", disposition: "inline"
    end
  end
  
  def total_studies_certificate
    @r_root    = Rails.root.to_s
    t = Thesis.find(params[:thesis_id])
    libro = params[:libro]
    foja  = params[:foja]
    filename = "#{@r_root}/private/prawn_templates/certificado_estudios_totales.pdf"
    Prawn::Document.generate("full_template.pdf", :template => filename) do |pdf|
      pdf.font_families.update("Times" => {
        :bold        => "#{@r_root}/private/fonts/times/timesbd.ttf",
        :italic      => "#{@r_root}/private/fonts/times/timesi.ttf",
        :bold_italic => "#{@r_root}/private/fonts/times/timesbi.ttf",
        :normal      => "#{@r_root}/private/fonts/times/times.ttf"
      })
      pdf.font_families.update("Arial" => {
        :bold        => "#{@r_root}/private/fonts/arial/arialbd.ttf",
        :italic      => "#{@r_root}/private/fonts/arial/ariali.ttf",
        :bold_italic => "#{@r_root}/private/fonts/arial/arialbi.ttf",
        :normal      => "#{@r_root}/private/fonts/arial/arial.ttf"
      })
      pdf.font "Times"
 
      # SET FOLIO
      x = 462
      y = 626
      w = 40
      h = 9
      size = 9 
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "373435"
      text = "#{libro}-#{foja}"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :center, :valign=> :center

      # SET NAME
      x = 180
      y = 568
      w = 250
      h = 13
      size = 12
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "000000"
      text = t.student.full_name.mb_chars.upcase
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center
      
      # SET PROGRAM NAME
      x = 179
      y = 546
      w = 400
      h = 26
      size = 12
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "000000"
      text = t.student.program.name.mb_chars.upcase
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center,:valign=>:top

      pdf.font "Arial"
      ### SET COURSES
      ## CLEAN  PAGE 1
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [64,191], 20, 150
      pdf.fill_rectangle [117,197], 106, 150
      pdf.fill_rectangle [229,192], 45, 150
      pdf.fill_rectangle [285,192], 38, 150
      pdf.fill_rectangle [329,196], 84, 150

      ## CLEAN PAGE 2
      pdf.go_to_page(2)
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [72,575], 20, 150
      pdf.fill_rectangle [120,583], 106, 150
      pdf.fill_rectangle [231,575], 45, 150
      pdf.fill_rectangle [287,575], 38, 150
      pdf.fill_rectangle [330,575], 84, 150

      # CODE INITIAL DATA
      pdf.go_to_page(1)
      x = 64
      y = 191 
      w = 20 
      h = 9
      size = 8 
      # COURSE NAME INITIAL DATA
      x_1 = 117
      y_1 = 197
      w_1 = 106
      h_1 = 25
      size_1 = 8
      # TERMS INITIAL DATA
      x_2 = 229
      y_2 = 192
      w_2 = 45
      h_2 = 9
      size_2 = 7
      # GRADE INITIAL DATA
      x_3 = 285
      y_3 = 191
      w_3 = 38
      h_3 = 9
      size_3 = 8
      # GRADE ON TEXT INITIAL DATA
      x_4 = 329
      y_4 = 196
      w_4 = 84
      h_4 = 18
      size_4 = 8
      # GENERAL DATA
      text = ""
      counter = 0
 

      if t.student.program.level.to_i.eql? 2
        tcss = TermCourseStudent.joins(:term_student).joins(:term_course=>:course).where("term_students.student_id=? AND term_course_students.status=? AND term_course_students.grade>=? AND courses.program_id=?",t.student.id,TermCourseStudent::ACTIVE,70,t.student.program_id).order(:code)
      else
        tcss = TermCourseStudent.joins(:term_student).joins(:term_course=>:course).where("term_students.student_id=? AND term_course_students.status=? AND term_course_students.grade>=?",t.student.id,TermCourseStudent::ACTIVE,70).order(:code)
      end

        tcss.each do |tcs|
          counter= counter + 1
          ## SET CODE
          text= tcs.term_course.course.code

          pdf.fill_color "ffffff"
          pdf.fill_rectangle [x,y], w, h
          pdf.fill_color "000000"
          pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center
          
          y =  y - 50

          ## SET COURSE NAME
          text= tcs.term_course.course.name.mb_chars.upcase
          
          pdf.fill_color "ffffff"
          pdf.fill_rectangle [x_1,y_1], w_1, h_1
          pdf.fill_color "000000"
          pdf.text_box text , :at=>[x_1,y_1], :width => w_1, :height=> h_1, :size=>size_1, :style=> :bold, :align=> :center, :valign=> :center
          y_1 =  y_1 - 50

          ## SET TERM
          term = tcs.term_course.term.name
          year = term.at(2..3)
          subterm = term.at(5)

          text = "#{year}/#{subterm}"
          pdf.fill_color "ffffff"
          pdf.fill_rectangle [x_2,y_2], w_2, h_2
          pdf.fill_color "000000"
          pdf.text_box text , :at=>[x_2,y_2], :width => w_2, :height=> h_2, :size=>size_2, :style=> :bold, :align=> :center, :valign=> :center
          y_2 = y_2 - 50

          ## SET GRADE
          text = tcs.grade.to_s
          pdf.fill_color "ffffff"
          pdf.fill_rectangle [x_3,y_3], w_3, h_3
          pdf.fill_color "000000"
          pdf.text_box text , :at=>[x_3,y_3], :width => w_3, :height=> h_3, :size=>size_3, :style=> :bold, :align=> :center, :valign=> :center
          y_3 = y_3 - 50
          
          ## SET GRADE ON TEXT
          text = get_cardinal_name(tcs.grade.to_i)
          pdf.fill_color "ffffff"
          pdf.fill_rectangle [x_4,y_4], w_4, h_4
          pdf.fill_color "000000"
          pdf.text_box text.upcase , :at=>[x_4,y_4], :width => w_4, :height=> h_4, :size=>size_4, :style=> :bold, :align=> :center, :valign=> :center
          y_4 = y_4 - 50

          #### GO TO PAGE 2
          if counter == 3
            pdf.go_to_page(2)
            x = 72
            y = 575
            x_1 = 120
            y_1 = 583
            x_2 = 231
            y_2 = 575
            x_3 = 287
            y_3 = 575
            x_4 = 330
            y_4 = 580
          end
      end
      
      pdf.font "Arial"
      # DATE
      pdf.go_to_page(2)
      x = 260 
      y = 168
      w =  6
      h =  9
      size = 9
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "000000"
      text = "#{counter}"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center

      

      time = Time.new
      x = 150 
      y = 145
      w = 250
      h = 9
      size = 9
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "000000"
      text = "a #{time.day.to_s} de #{get_month_name(time.month)} del #{time.year.to_s}"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center

      # RENDER
      send_data pdf.render, type: "application/pdf", disposition: "inline"
    end
  end



  def diploma
    time = Time.new
    
    t = Thesis.find(params[:thesis_id])
    libro = params[:libro]
    foja  = params[:foja]

    diploma          = "diploma-#{libro}-#{foja}.docx"
    documento_xml    = "documento-#{libro}-#{foja}.docx"

    ruta_template = Rails.root.join('private','docx','diploma-template.docx')
    ruta_destino = Rails.root.join('tmp',diploma)
    
    xml_template = Rails.root.join('private','docx','document-template.xml')
    xml_destino = Rails.root.join('tmp',documento_xml)
 
    $stdout.binmode

    logger.debug ruta_template.to_s
    logger.debug ruta_destino.to_s


    FileUtils.cp ruta_template.to_s,ruta_destino.to_s
    FileUtils.cp xml_template.to_s,xml_destino.to_s
 
    filename = xml_destino.to_s
    substring filename,/alumnox/,t.student.full_name
    substring filename,/gradox/,t.student.program.name
    substring filename,/diax/,t.defence_date.day.to_s
    substring filename,/mesx/,get_month_name(t.defence_date.month)
    substring filename,/aniox/,t.defence_date.year.to_s
    substring filename,/diay/,time.day.to_s
    substring filename,/mesy/,get_month_name(time.month)
    substring filename,/anyoy/,time.year.to_s
    substring filename,/librox/,libro.to_s
    substring filename,/fojax/,foja.to_s
    bar_txt = open(filename)
 
    Zip::Archive.open(ruta_destino.to_s) do |ar|
      ar.replace_io("word/document.xml", bar_txt)
    end

    zip_data = File.read(ruta_destino.to_s)
    
    send_data(zip_data, :filename => documento_xml.to_s , :type => "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    return
  end 

  def substring(filename,regexp,replacestring)
    text = File.read(filename) 
    puts = text.gsub(regexp,replacestring)
    File.open(filename, "w") { |file| file << puts }
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
