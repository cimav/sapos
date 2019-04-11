# coding: utf-8
require 'digest/md5'
require 'csv'
require 'tempfile'

class StudentsController < ApplicationController
  REALM = "Students"
  PASS  = Digest::MD5.hexdigest(["dap",REALM,"53cr3t"].join(":"))
  USERS = {"u1"=>PASS}
  before_filter :auth_required,:except=>[:student_exists]
  before_filter :set_current_user
  respond_to :html, :xml, :json, :csv

  def index
    @remote_id = params[:student_id] || "'x'"

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
    @programs_json = @programs.select("programs.id, programs.name").all
  end

  def live_search
    @order_by = params[:order_by] || "last_name"
    if current_user.program_type==Program::ALL
      @students = Student.select("id,first_name,last_name,program_id,card,gender").order(@order_by).includes(:program)
    else
      @students = Student.select("id,first_name,last_name,program_id,card,gender").joins(:program => :permission_user).where(:permission_users=>{:user_id=>current_user.id}).order(@order_by).includes(:program)
    end

    if params[:program_type] != '0' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").joins(:program).where(:programs=>{:program_type=>params[:program_type]})
    end

    if params[:program] != '0' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where(:program_id => params[:program])
    end

    if current_user.campus_id != 0
      params[:campus] = current_user.campus_id
    end

    if params[:campus] != '0' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where(:campus_id => params[:campus])
    end

    if params[:supervisor] != '0' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("(supervisor = :supervisor OR co_supervisor = :supervisor)", {:supervisor => params[:supervisor]})
    end

    if params[:status] == 'todos_activos' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("status = #{Student::ACTIVE}")
    end

    if params[:status] == 'activos_inscritos' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("status = #{Student::ACTIVE} AND students.id IN (SELECT student_id FROM terms INNER JOIN term_students ON terms.id = term_id WHERE terms.status IN (#{Term::OPEN}, #{Term::PROGRESS}, #{Term::GRADING}))")
    end

    if params[:status] == 'activos_no_inscritos' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("status = #{Student::ACTIVE} AND students.id NOT IN (SELECT student_id FROM terms INNER JOIN term_students ON terms.id = term_id WHERE terms.status IN (#{Term::OPEN}, #{Term::PROGRESS}, #{Term::GRADING}))")
    end

    if params[:status] == 'todos_egresados' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("status IN (#{Student::GRADUATED}, #{Student::FINISH})")
    end

    if params[:status] == 'egresados_graduados' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("status = #{Student::GRADUATED}")
    end

    if params[:status] == 'egresados_no_graduados' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("status = #{Student::FINISH}")
    end

    if params[:status] == 'baja_temporal' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("status = #{Student::INACTIVE}")
    end

    if params[:status] == 'baja_definitiva' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("status = #{Student::UNREGISTERED}")
    end

    if params[:status] == 'preinscritos' then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("status = #{Student::PENROLLMENT}")
    end

    # filtrar por beca
    if params[:scholarship_type] != "10" then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("scholarship_type = #{params[:scholarship_type]}")
    end

    # filtrar por tiempo de estudio
    if params[:student_time] != "10" then
      @students = @students.select("id,first_name,last_name,program_id,card,gender").where("student_time = #{params[:student_time]}")
    end


=begin
    if !params[:q].blank?
      if params[:q].to_i != 0
        @students = @students.where("id = ?",params[:q].to_i)
      else
        @students = @students.where("(CONCAT(first_name,' ',last_name) LIKE :n OR card LIKE :n)", {:n => "%#{params[:q]}%"})
      end
    end
=end


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
      @students = @students.select("id,first_name,last_name,program_id,card").where("status IN (#{s.join(',')})")
    end

    # Descartamos los que tienen status de borrado
    #@students = @students.where("status<>0")

    respond_with do |format|
      format.html do
         render json: @students.select("id,first_name,last_name,last_name2,program_id,card,image")
      end
      format.xls do
        rows = Array.new
        now = Time.now.utc
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

          if s.date_of_birth.nil?
            age = 0
          else
            age = now.year - s.date_of_birth.year - (s.date_of_birth.to_time.change(:year => now.year) > now ? 1 : 0)
          end
          last_advance = s.advance.where(:status=>["P","C"],).order(:advance_date).first

	  rows << {'Matricula' => s.card,
		   'Nombre' => s.first_name,
		   'Apellidos' => s.last_name,
                   'Correo'  => s.email,
                   'Sexo' => s.gender,
		   'Estado' => s.status_type,
		   "Fecha_Nac" => s.date_of_birth,
                   "Edad(#{now.year})" => age, 
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
       'Ubicacion' => s.location,
		   'Tesis' => s.thesis.title,
		   'Sinodal1' => (Staff.find(s.thesis.examiner1).full_name rescue ''),
		   'Sinodal2' => (Staff.find(s.thesis.examiner2).full_name rescue ''),
		   'Sinodal3' => (Staff.find(s.thesis.examiner3).full_name rescue ''),
		   'Sinodal4' => (Staff.find(s.thesis.examiner4).full_name rescue ''),
		   'Sinodal5' => (Staff.find(s.thesis.examiner5).full_name rescue ''),
                   'Fecha_Avance' => (last_advance.advance_date rescue ''),
                   'Tutor1' => (Staff.find(last_advance.tutor1).full_name rescue ''),
                   'Tutor2' => (Staff.find(last_advance.tutor2).full_name rescue ''),
                   'Tutor3' => (Staff.find(last_advance.tutor3).full_name rescue ''),
                   'Tutor4' => (Staff.find(last_advance.tutor4).full_name rescue ''),
                   'Tutor5' => (Staff.find(last_advance.tutor5).full_name rescue ''),
		   }
             
	end
	column_order = ["Matricula", "Nombre", "Apellidos","Correo", "Sexo", "Estado", "Fecha_Nac", "Edad(#{now.year})", "Ciudad_Nac", "Estado_Nac", "Pais_Nac", "Institucion_Anterior", "Campus", "Programa", "Inicio", "Fin", "Meses", "Asesor", "Coasesor","Ubicacion", "Tesis", "Sinodal1", "Sinodal2", "Sinodal3", "Sinodal4", "Sinodal5","Fecha_Avance","Tutor1","Tutor2","Tutor3","Tutor4","Tutor5"]
	to_excel(rows, column_order, "Estudiantes", "Estudiantes")
      end
    end
  end

  def set_xls
    rows = Array.new
    now = Time.now.utc
    items = params[:items].split(",")
    order_by = params[:order_by] || "last_name"

    Student.where(:id=>items).order(order_by).collect do |s|
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

      if s.date_of_birth.nil?
        age = 0
      else 
        age = now.year - s.date_of_birth.year - (s.date_of_birth.to_time.change(:year => now.year) > now ? 1 : 0) 
      end  
      last_advance = s.advance.where(:status=>["P","C"],).order(:advance_date).first



      rows << {'Matricula' => s.card,
        'Nombre' => "#{s.full_name_by_last}",
        'Correo' =>(s.email_cimav.blank? ? s.email : s.email_cimav),
        'Sexo'   => s.gender,
        'Estado' => s.status_type,
        "Fecha_Nac" => s.date_of_birth,
        "Edad(#{now.year})" => age, 
        "Ciudad_Nac" => s.city,
        "Estado_Nac" => (s.state.name rescue ''),
        "Pais_Nac"   => (s.country.name rescue ''),
        "Institucion_Anterior" => (Institution.find(s.previous_institution).full_name rescue ''),
        "Campus"     => (s.campus.name rescue ''),
        'Programa'   => s.program.name,
        'Promedio'   => (s.get_average rescue ''),
        'Inicio'     => s.start_date,
        'Fin'        => end_date,
        'Meses'      => months,
        'Asesor'     => (Staff.find(s.supervisor).full_name rescue ''),
        'Coasesor'   => (Staff.find(s.co_supervisor).full_name rescue ''),
        'Tesis'      => s.thesis.title,
        'Ubicacion'  => s.location,
        'Sinodal1'   => (Staff.find(s.thesis.examiner1).full_name rescue ''),
        'Sinodal2'   => (Staff.find(s.thesis.examiner2).full_name rescue ''),
        'Sinodal3'   => (Staff.find(s.thesis.examiner3).full_name rescue ''),
        'Sinodal4'   => (Staff.find(s.thesis.examiner4).full_name rescue ''),
        'Sinodal5'   => (Staff.find(s.thesis.examiner5).full_name rescue ''),
        'Fecha_Avance' => (last_advance.advance_date rescue ''),
        'Tutor1'     => (Staff.find(last_advance.tutor1).full_name rescue ''),
        'Tutor2'     => (Staff.find(last_advance.tutor2).full_name rescue ''),
        'Tutor3'     => (Staff.find(last_advance.tutor3).full_name rescue ''),
        'Tutor4'     => (Staff.find(last_advance.tutor4).full_name rescue ''),
        'Tutor5'     => (Staff.find(last_advance.tutor5).full_name rescue ''),
        'Fecha_baja_definitiva' => (s.definitive_inactive_date rescue ''),
        'Fecha_baja_temporal'   => (s.inactive_date rescue '')
      }
    end#Students

    column_order = ["Matricula", "Nombre", "Correo", "Sexo", "Estado", "Fecha_Nac", "Edad(#{now.year})", "Ciudad_Nac", "Estado_Nac", "Pais_Nac", "Institucion_Anterior", "Campus", "Programa","Promedio", "Inicio", "Fecha_baja_temporal", "Fecha_baja_definitiva", "Fin", "Meses", "Asesor", "Coasesor","Ubicacion", "Tesis", "Sinodal1", "Sinodal2", "Sinodal3", "Sinodal4", "Sinodal5","Fecha_Avance","Tutor1","Tutor2","Tutor3","Tutor4","Tutor5"]

    @filename = to_excel(rows, column_order, "Estudiantes", "Estudiantes",1)
    render :layout => false
  end

  def get_xls
    uri = "tmp/#{params[:file]}.xls"
    send_file uri, :x_sendfile=>true
  end

  def show
    #@student = Student.includes(:program, :thesis, :contact, :scholarship, :advance).find(params[:id])
    @student = Student.includes(:program, :contact).find(params[:id])
    @applicant_id = 0

    program_id  = @student.program_id
    if program_id.to_i.eql? 6
      program_id = 1
    elsif program_id.to_i.eql? 7
      program_id = 3
    end
    
    @staffs = Staff.order('first_name').includes(:institution).where(:status=>0)

    if !@student.supervisor.nil?
      if !@student.supervisor.zero?
        s = Staff.find(@student.supervisor)
        if s.status.to_i.eql? 1
          @staffs << s
        end
      end
    end

    if !@student.co_supervisor.nil?
      if !@student.co_supervisor.zero?
        s = Staff.find(@student.co_supervisor)
        if s.status.to_i.eql? 1
          @staffs << s
        end
      end
    end

    if !@student.external_supervisor.nil?
      if !@student.supervisor.zero?
        s = Staff.find(@student.external_supervisor)
        if s.status.to_i.eql? 1
          @staffs << s
        end
      end
    end
    
    @countries = Country.order('name')
    @institutions = Institution.order('name')
    @states = State.order('code')
    @status = Student::STATUS


    if @student.status == Student::UNREGISTERED
      end_date = @student.definitive_inactive_date
    else
      if @student.thesis.status.eql? "C"
        end_date = @student.thesis.defence_date
      else
        end_date = Date.today
      end
    end

    yyyy  = end_date.year - @student.start_date.year
    m = end_date.month - @student.start_date.month

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

  def contact
    #@student   = Student.includes(:program, :contact).find(params[:id])
    @student   = Student.find(params[:id]) 
    @countries = Country.order('name')
    @states    = State.order('code')
    render :layout => false
  end

  def advance
    @student   = Student.find(params[:id])
    @staffs    = Staff.where(:status=>0).order('first_name')
    render :layout => false
  end

  def thesis
    @student   = Student.find(params[:id]) 
    @staffs    = Staff.where(:status=>0).order('first_name')
    render :layout => false
  end

  def files_show
    @student   = Student.find(params[:id]) 
    render :layout => false
  end

  def payments_show
    @student   = Student.find(params[:id]) 
    render :layout => false
  end
  
  def certificates_show
    @student   = Student.find(params[:id]) 
    render :layout => false
  end

  def documents
    @student      = Student.find(params[:id])
    #if @student.program.program_type.eql? 4
      @applicants   = Applicant.where(:student_id=>@student.id,:campus_id=>@student.campus_id)
    #else
    #  @applicants   = Applicant.where(:student_id=>@student.id,:campus_id=>@student.campus_id,:program_id=>@student.program_id)
    #end


    if @applicants.size>0
      @applicant_id = @applicants[0].id
    else
      @applicant_id = 0
    end

    render :layout => false
  end

  def schedule
    @student      = Student.find(params[:id]) 
    render :layout => false
  end

  def grades
    @student      = Student.find(params[:id]) 
    render :layout => false
  end

  def kardex_show
    @student      = Student.find(params[:id]) 
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
            json[:version] = 1
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
	    json[:flash]  = flash
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
    if (@student.status.to_i==Student::GRADUATED and @student.exstudent.nil?)
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
    if @student.update_attribute(:image, params[:student][:image])
      flash[:notice] = "Imagen actualizada."
    else
      logger.debug "######################## AQUI"
      @student.errors.each{|attr,message| logger.debug "######### #{attr} #{message}"}
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
  
  def upload_one_file
    flash = {}
    if params[:student_file].nil?
      render :inline => "<status>0</status><reference>upload</reference><errors>No ha seleccionado archivo</errors>"
      return
    end

    f = params[:student_file]['file']
    @student_file = StudentFile.new
    @student_file.student_id = params[:student_id]
    @student_file.file_type = params[:file_type]
    @student_file.file = f
    @student_file.description = f.original_filename
    if @student_file.save
      render :inline => "<status>1</status><reference>upload</reference><id>#{@student_file.id}</id>"
    else
      render :inline => "<status>0</status><reference>upload</reference><errors>#{@student_file.errors.full_messages}</errors>"
    end
  #rescue  
  #  render :inline => "<status>0</status><reference>upload</reference><errors>Error general</errors>"
  end

  def file
    s = Student.find(params[:id])
    sf = s.student_file.find(params[:file_id]).file
    send_file sf.to_s, :x_sendfile=>true
  end

  def get_protocol
    advance   = Advance.find(params[:id])
    staff_id  = params[:staff_id]
    filename  = "#{Settings.sapos_route}/private/files/students/#{advance.student.id}"
    if advance.advance_type.eql? 2
      pdf_route = "#{filename}/protocol-#{advance.id}-#{staff_id}.pdf"
    elsif advance.advance_type.eql? 3
      pdf_route = "#{filename}/seminar-#{advance.id}-#{staff_id}.pdf"
    end
    send_file pdf_route, :x_sendfile=>true
  end

  def get_protocol_cep
    advance  = Advance.find(params[:id])
    staff    = Staff.find(params[:staff_id])
    protocol = Protocol.where(:staff_id=>params[:staff_id],:advance_id=>advance.id)[0] rescue nil

    if ((protocol.status.to_i.eql? 4) && (protocol.grade_status.to_i.eql? 3))
      render :text => "Protocolo en revision de recomendaciones"
      return
    end

    create_protocol(protocol,staff,advance)
  end

  def create_protocol(protocol,staff,advance)
    @r_root  = Rails.root.to_s

    supervisor      = Staff.find(advance.student.supervisor) rescue nil
    supervisor_name = supervisor.full_name rescue "N.D"
    supervisor_area = supervisor.area.name rescue "N.D"

    created = "#{advance.created_at.day} de #{get_month_name(advance.created_at.month)} de #{advance.created_at.year}"

    pdf = Prawn::Document.new(:margin=>[20,43,43,43])
    size = 14

    if advance.advance_type.eql? 2
      pdf.move_down 30
      text = "FORMATO P-MA-E"
      pdf.text text, :size=>size, :style=> :bold, :align=> :center

      pdf.move_down 1
      text = "EVALUACIÓN PROTOCOLOS"
      pdf.text text ,:size=>size, :style=> :bold, :align=> :center
    elsif advance.advance_type.eql? 3
      pdf.move_down 31
      text = "SEMINARIO FINAL"
      pdf.text text ,:size=>size, :style=> :bold, :align=> :center
    end

    size = 11

    pdf.move_down 10
    data = []
    data << [{:content=>"Fecha de Evaluación: #{created}",:colspan=>2,:align=>:right}]
    data << [{:content=>" ",:colspan=>2}]
    data << ["Nombre del Alumno:",advance.student.full_name]
    data << ["Nombre del Director de Tesis:",supervisor_name]
    data << ["Departamento:",supervisor_area]
    data << ["Programa:",advance.student.program.name]
    data << ["Título de la Tesis:",advance.title]

    tabla = pdf.make_table(data,:width=>530,:cell_style=>{:size=>size,:padding=>2,:inline_format => true,:border_width=>0},:position=>:center,:column_widths=>[165,365])
    tabla.draw

    pdf.move_down 10

    icon_empty = pdf.table_icon('fa-square-o')
    icon_ok    = pdf.table_icon('fa-check-square-o')
    content1   = icon_empty

    protocol.reload.answers.each do |a|
      pdf.move_down 10
      question = Question.find(a.question_id)
      text     = question.question rescue "N.D"
      
      if text.eql? "Recomendaciones"
        text = ""
      end

      pdf.text text, :size=>size, :style=>:bold

      data = []
      if question.question_type.to_i.eql? 1  ## multiple option
        (a.answer.eql? 4) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Excelente"]
        (a.answer.eql? 3) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Bien"]
        (a.answer.eql? 2) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Regular"]
        (a.answer.eql? 1) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Deficiente"]
      elsif question.question_type.to_i.eql? 2 ## text
        answer = "" #a.comments rescue "n.d."
        data << [{:content=>"#{answer}",:colspan=>2}]
      elsif question.question_type.to_i.eql? 3 ## grade
        answer = a.answer rescue "n.d."
        data << [{:content=>"#{answer}",:colspan=>2}]
      end
        tabla = pdf.make_table(data,:width=>530,:cell_style=>{:size=>size,:padding=>2,:inline_format => true,:border_width=>0},:position=>:center,:column_widths=>[30,500])
        tabla.draw
    end  ## end protocol.answeers

    pdf.move_down 10
    data = []
    data << [{:content=>"<b>Resultado</b>",:colspan=>2}]

    icon_empty = pdf.table_icon('fa-square-o')
    icon_ok    = pdf.table_icon('fa-check-square-o')
    content1   = icon_empty

    if advance.advance_type.eql? 2 #protocol
      (protocol.grade_status.eql? 1) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,"Aprobado"]
      (protocol.grade_status.eql? 2) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,"No aprobado"]
    elsif advance.advance_type.eql? 3 #seminar
      if ((protocol.grade_status.eql? 1)&&(protocol.status.eql? 3))
        data << [icon_ok,{:content=>"Aprobado",:align=>:left}]
        data << [icon_empty,"No aprobado"]
        data << [icon_empty,"Con Recomendaciones"]
      elsif((protocol.grade_status.eql? 1)&&(protocol.status.eql? 3))
        data << [icon_empty,{:content=>"Aprobado",:align=>:left}]
        data << [icon_ok,"No aprobado"]
        data << [icon_empty,"Con Recomendaciones"]
      elsif ((protocol.grade_status.eql? 1)&&(protocol.status.eql? 4)) ? content1 = icon_ok : content1 = icon_empty
        data << [icon_ok,{:content=>"Aprobado",:align=>:left}]
        data << [icon_empty,"No aprobado"]
        data << [icon_ok,"Con Recomendaciones atendidas"]
      elsif ((protocol.grade_status.eql? 2)&&(protocol.status.eql? 4)) ? content1 = icon_ok : content1 = icon_empty
        data << [icon_empty,{:content=>"Aprobado",:align=>:left}]
        data << [icon_ok,"No aprobado"]
        data << [icon_ok,"Con Recomendaciones atendidas"]
      else
      end
      
    end

    tabla = pdf.make_table(data,:width=>300,:cell_style=>{:size=>size,:padding=>2,:inline_format => true,:border_width=>0},:position=>:left,:column_widths=>[30,270])
    tabla.draw

    pdf.text "\nCon promedio de #{protocol.grade}"

    send_data pdf.render, type: "application/pdf", disposition: "inline"
  end#get_protocol_cep

  def delete_file
  end

  def new_advance
    @student      = Student.find(params[:id])
    @staffs       = Staff.where(:status=>0).order('first_name')
    @last_advance = @student.advance.where(:status=>["P","C"],).order(:advance_date).first
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
    if current_user.access.in? [User::ADMINISTRATOR,User::MANAGER,User::OPERATOR_READER]
      @advances = Advance.where("advance_date>=CURDATE() AND advance_date<=DATE_ADD(CURDATE(),INTERVAL 30 DAY)").reorder("advance_date ASC")
    elsif  current_user.access == User::OPERATOR
      @advances = Advance.joins(:student).where("advance_date>=CURDATE() AND advance_date<=DATE_ADD(CURDATE(),INTERVAL 30 DAY) AND campus_id=:campus_id",{:campus_id=>current_user.campus_id}).reorder("advance_date ASC")
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
        if params[:ext].to_i.eql? 1
          ActivityLog.new({:user_id=>current_user.id,:activity=>"Imprime credencial extemporanea: #{@student.id} notas: #{params[:notes]}"}).save
        else
          ActivityLog.new({:user_id=>current_user.id,:activity=>"Imprime credencial: #{@student.id}"}).save
        end
        @extension  = Date.new(params[:year].to_i,params[:month].to_i,params[:day].to_i) rescue nil
        html = render_to_string(:layout => false , :template => "students/id_card.html.haml", :formats => [:html], :handlers => [:haml])
        kit = PDFKit.new(html, :page_size => 'Legal', :orientation => 'Landscape', :margin_top    => '0',:margin_right  => '0', :margin_bottom => '0', :margin_left   => '0')
        kit.stylesheets << "#{Rails.root}/public/cards.css"
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
    @student     = Student.includes(:program, :thesis, :contact, :scholarship, :advance).find(params[:id])
    @nombre      = @student.full_name
    @matricula   = @student.card
    @programa    = @student.program.name
    @sign        = params[:sign_id]
    city        = params[:city]
    dir          = t(:directory)
    options      = {}
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

    ################################ CONSTANCIA DE ESTUDIOS ##################################
    if params[:type] == "estudios"

      options[:cert_type] = Certificate::STUDIES

      options[:text] = "#{@sgenero2.camelcase} suscrit#{@sgenero} <b>#{@firma}</b>, #{@puesto} del Centro de Investigación en Materiales Avanzados, S.C., hace constar que <b>#{@nombre}</b> de matrícula <b>#{@matricula}</b> está inscrit#{@genero} como alumn#{@genero} regular en nuestro programa #{@programa}"

      options[:filename] =  "constancia-estudios-#{@student.id}.pdf"
    end

    ################################ CONSTANCIA DE INSCRIPCION  ##################################
    if params[:type] == "inscripcion"
      options[:cert_type] = Certificate::ENROLLMENT

      time        = Time.new
      @month      = get_month_name(time.month)
      @start_month= get_month_name(@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.start_date.month).capitalize
      @end_month  = get_month_name(@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.end_date.month).capitalize
      @end_year   = @student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.end_date.year.to_s
      
      options[:text] = "#{@sgenero2.camelcase} suscrit#{@sgenero} #{@firma}, #{@puesto} del Centro de Investigación en Materiales Avanzados, S.C., hace constar que <b>#{@nombre}</b> de matrícula <b>#{@matricula}</b> está inscrit#{@genero} como alumn#{@genero} activ#{@genero} en el periodo <b>#{@start_month} - #{@end_month} #{@end_year}</b>, en nuestro programa #{@programa}"
      options[:filename] =  "constancia-inscripcion-#{@student.id}.pdf"
    end

    ################################ CONSTANCIA PARA VISA  ##################################
    if params[:type] == "visa"
      options[:cert_type] = Certificate::VISA

      options[:text] = "#{@sgenero2.camelcase} suscrit#{@sgenero} <b>#{@firma}</b>, #{@puesto} del Centro de Investigación en Materiales Avanzados, S.C., Centro Público de Investigación con clave de Institución 080068 y con programas registrados ante la Dirección General de Profesiones de la Secretaría de Educación Pública, hace constar que #{@genero2} alumn#{@genero} <b>#{@nombre}</b> de matrícula <b>#{@matricula}</b> se encuentra inscrit#{@genero} como alumno regular en nuestro programa #{@programa}"

      options[:filename] = "constancia-visa-#{@student.id}.pdf"
    end

    ################################ CONSTANCIA DE PROMEDIO GENERAL  ##################################
    if params[:type] == "promedio"
      options[:cert_type] = Certificate::AVERAGE
      @nombre      = @student.full_name
      @matricula   = @student.card
      @programa    = @student.program.name
      @semestre    = @student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.code

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
      @promedio = avg.to_s

      options[:text] = "#{@sgenero2.camelcase} suscrit#{@sgenero} <b>#{@firma}</b>, #{@puesto} del Centro de Investigación en Materiales Avanzados, S.C., Centro Público de Investigación, hace constar que <b>#{@nombre}</b> de matricula <b>#{@matricula}</b> está inscrit#{@genero} como alumn#{@genero} regular del semestre #{@semestre} en nuestro programa de #{@programa}"
      options[:average] = @promedio

      options[:filename] = "constancia-promedio-general-#{@student.id}.pdf"
    end

    ################################ CONSTANCIA DE PROMEDIO SEMESTRAL  ##################################
    if params[:type] == "semestral"
      options[:cert_type] = Certificate::SEMESTER_AVERAGE

      ts = @student.term_students.joins(:term).order("terms.start_date")
      term = ts.last.term
      @semestre = term.code
      avg = get_semester_average(term)

      if avg.eql? 0
        term = ts[ts.size - 2].term
        avg = get_semester_average(term)
      end

      @promedio         = avg.to_s
      @semestre_cursado = term.code
   
      options[:text] = "#{@sgenero2.camelcase} suscrit#{@sgenero} <b>#{@firma}</b>, #{@puesto}, del Centro de Investigación en Materiales Avanzados, S.C., hace constar que <b>#{@nombre}</b> de matrícula <b>#{@matricula}</b> está inscrit#{@genero} como alumn#{@genero} regular en nuestro programa de #{@programa}"
      options[:average]        = @promedio
      options[:last_semester]  = @semestre_cursado

      options[:filename] = "constancia-promedio-semestral-#{@student.id}.pdf"
    end

    ################################ CONSTANCIA DE TRAMITE DE SEGURO  ##################################
    if params[:type] == "seguro"
      options[:cert_type] = Certificate::SOCIAL_WELFARE

      @start_day    = @student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.start_date.day.to_s
      @end_day      = @student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.end_date.day.to_s
      @start_month  = get_month_name(@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.start_date.month).capitalize
      @end_month    = get_month_name(@student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.end_date.month).capitalize
      @start_year   = @student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.start_date.year.to_s
      @end_year     = @student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.end_date.year.to_s

      @creditos     =  get_credits(@student)
      @promedio     = @student.get_average
      @result = @student.scholarship.where("scholarships.status = 'ACTIVA' AND scholarships.start_date<=CURDATE() AND scholarships.end_date>=CURDATE()")
      @semestre = @student.term_students.joins(:term).order("terms.start_date desc").limit(1)[0].term.code

      @periodo = " durante el periodo del"
      if @end_year == @start_year
        @periodo = "#{@periodo} <b>#{@start_day} de #{@start_month}</b> al <b>#{@end_day} de #{@end_month} de #{@end_year}</b>."
      else
        @periodo= "#{@periodo} <b>#{@start_day} de #{@start_month} de #{@start_year}</b> al <b>#{@end_day} de #{@end_month} de #{@end_year}</b>."
      end

      options[:text] = "#{@sgenero2.camelcase} suscrit#{@sgenero} <b>#{@firma}</b>, #{@puesto} del Centro de Investigación en Materiales Avanzados, S.C., Centro Público de Investigación con clave de Institución 080068 y con programas registrados ante la Dirección General de Profesiones de la Secretaría de Educación Pública, hace constar que #{@genero2} alumn#{@genero} <b>#{@nombre}</b> de matrícula <b>#{@matricula}</b>, está inscrit#{@genero} como alumn#{@genero} regular el semestre #{@semestre} de nuestro programa #{@programa} #{@periodo}"

      options[:filename] = "constancia-tramite-seguro-#{@student.id}.pdf"
    end

    ################################ CONSTANCIA DE CREDITOS CUBIERTOS  ##################################
    if params[:type] == "creditos"
      options[:cert_type] = Certificate::CREDITS

      @programa     = @student.program.name
      @creditos     = get_credits(@student)
      @promedio     = @student.get_average

      @creditos_totales = StudiesPlan.find(@student.studies_plan_id).total_credits.to_s rescue "N.D"

      if @student.program.level.eql? "1"
        @nivel            = "de la Maestría"
      elsif @student.program.level.eql? "2"
        @nivel            = "del Doctorado"
      else
        @nivel            = "Unknown"
      end

      options[:text] = "#{@sgenero2.camelcase} suscrit#{@sgenero} <b>#{@firma}</b>, #{@puesto}, del Centro de Investigación en Materiales Avanzados, S.C., hace constar que #{@genero2} alumn#{@genero} <b>#{@nombre}</b> con número de registro <b>#{@matricula}</b> está inscrit#{@genero} como alumn#{@genero} regular en nuestro programa #{@programa} en este centro de investigación.\n\nLos créditos #{@nivel} son #{@creditos_totales}, con un total de #{@creditos} créditos cubiertos; obteniendo un promedio global de #{@promedio}."
      options[:filename] = "constancia-creditos-cubiertos-#{@student.id}.pdf"
    end
   
    generate_certificate(options)
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
    background = "#{Rails.root.to_s}/private/prawn_templates/membretada.png"
    #head = File.read("#{Rails.root}/app/views/students/certificates/head.html")
    #base = File.read("#{Rails.root}/app/views/students/certificates/base.html")
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

    @consecutivo = get_consecutive(@student, time, Certificate::EXAMINER)
    @rails_root  = "#{Rails.root}"
    @year_s      = year[2,4]
    @year        = year
    @days        = time.day.to_s
    @month       = get_month_name(time.month)
    @nombre      = @student.full_name
    @matricula   = @student.card
    @programa    = @student.program.name
    @asesor      = Staff.find(params[:staff_id]).full_name rescue ""
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

      pdf.text "\n\n\n\n\n\n\n\n\n\nCoordinación de estudios de Posgrado\nNo° de Oficio  PO - #{@consecutivo}/#{@year}\n Chihuahua, Chih, a #{@days} de #{@month} de #{@year}.", :inline_format=>true, :align=>:right 

      x = 20
      y -= 70
      w = 300
      pdf.font_size 12
      
      @a_quien_corr = "A quien corresponda\n\n <b>Presente.</b>\n"

      pdf.text @a_quien_corr, :align=>:justify, :inline_format=>true

      x = 20
      y -= 160
      w = 300

      @parrafo1 = "\nPor medio de la presente tengo el agrado de extender la constancia a <b>#{@asesor}</b> de <b>#{@institution}</b> quien fungio como sinodal externo del examen de Grado presentado el día de hoy, por #{@genero2} alumn#{@genero2} <b>#{@nombre}</b> de matrícula <b>#{@matricula}</b> de nuestro programa de <b>#{@programa}</b> con la tesis titulada: <b>#{@thesis_title}</b>\n"

      pdf.text @parrafo1, :align=>:justify, :inline_format=>true
      @parrafo2 = "\nSe extiende la presente constancia en la ciudad de Chihuahua, Chihuahua el dia #{@days} del mes de #{@month} de #{@year}, para los fines legales a que haya lugar."
      y -= 40
      x = 20
      pdf.text @parrafo2, :align=>:justify,:inline_format=>true
      
      y = y - 100 #202
      h = 155
      x = 98

      @atentamente = "\n\n\n\n<b>A t e n t a m e n t e\n\n\n\n#{@firma}\n#{@puesto}</b>"
      pdf.text_box @atentamente, :at=>[x,y], :align=>:center,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
      filename = "constancia-sinodal-externo-#{@student.id}.pdf"
       
      send_data(pdf.render, :filename => filename, :type => 'application/pdf', disposition:'inline')
    end
  end

  def grade_certificates
    @r_root     = Rails.root.to_s
    @time       = Time.now
    @thesis     = Thesis.find(params[:thesis_id])
    @level      = @thesis.student.program.level
    @rectangles = false

    @examiner1 = Staff.find(@thesis.examiner1)
    @examiner2 = Staff.find(@thesis.examiner2)
    @examiner3 = Staff.find(@thesis.examiner3)
    @examiner4 = Staff.find(@thesis.examiner4) rescue nil
    @examiner5 = Staff.find(@thesis.examiner5) rescue nil

    filename = "#{@r_root}/private/prawn_templates/acta_de_grado.pdf"
    pdf = Prawn::Document.new(:page_size=>"LETTER",:page_layout=>:portrait,:margin=>[13,15,15,15])
    pdf.font_families.update("Arial" => {
      :bold        => "#{@r_root}/private/fonts/arial/arialbd.ttf",
      :italic      => "#{@r_root}/private/fonts/arial/ariali.ttf",
      :bold_italic => "#{@r_root}/private/fonts/arial/arialbi.ttf",
      :normal      => "#{@r_root}/private/fonts/arial/arial.ttf"
    })

    pdf.font "Arial"
    pdf.fill_color "373435"
    #pdf.stroke_bounds
    # pdf.stroke_axi
    x = 93
    y = 467
    w = 72
    h = 104
    pdf.stroke_ellipse [x,y],w,h
    x2 = x - w/2
    y2 = y + h/2
    size = 8
    pdf.text_box "Fotografía\n Tamaño Título", :at=>[x2,y2], :size=>size, :width=>75,:height=>90, :align=>:center, :valign=>:center
    # TITLE
    x = 0
    y = 690
    size = 14
    pdf.text_box "Acta de Examen de Grado",:at=>[x,y],:style=>:bold, :align=>:center,:size=>size
    # SET HOUR AND DAY
    @hora = "%02d:%02d horas, del día %02d" % [@thesis.defence_date.hour,@thesis.defence_date.min,@thesis.defence_date.day]
    x = 230   #388
    y = 676  #629
    w = 310   #150
    h = 40    #11
    size = 12 #10

    # SET MONTH AND YEAR
    month = get_month_name(@thesis.defence_date.month)
    year = @thesis.defence_date.year
    char_spacing = 1.1

    if month.size.eql? 10 ## septiembre
      char_spacing = 0.58
    elsif month.size.eql? 9
      char_spacing = 0.67
      if month.eql? "diciembre"
        char_spacing = char_spacing + 0.09
      end
    elsif month.size.eql? 7
      char_spacing = 1.15  ## febrero
      if month.eql? "octubre"
        char_spacing = 1.1
      end
    elsif month.size.eql? 6 ## agosto
      char_spacing = 1.23
    elsif month.size.eql? 5
      char_spacing = 1.41 ## enero
      if month.eql? "marzo"
        char_spacing = 1.34
      elsif month.eql? "abril"
        char_spacing = 1.6
      elsif month.eql? "junio"
        char_spacing = 1.55
      elsif month.eql? "julio"
        char_spacing = 1.65
      end
    elsif month.size.eql? 4
      char_spacing = 1.46
    end

    l = 0
    pdf.bounding_box [x + 5,y - 2],:width => w + 10, :height=> h,:kerning=>true do
      #pdf.stroke_bounds
      pdf.text "En Chihuahua,Chih., a las #{@hora}", :size=> size, :leading=>l,:character_spacing=>0.1
      @m_y = "del mes #{month} de #{year}. Se reunieron los"
      pdf.text @m_y, :size=> size, :leading=>l,:character_spacing=>char_spacing
      pdf.text "miembros del jurado integrado por los señores(as):", :size=> size, :leading=>l, :character_spacing=>0.0
    end

    # SET  THESIS EXAMINERS
    x = 235
    y = 618
    size = 12
    if (@level.to_i.eql? 1)||(@level.to_i.eql? 2)
      text = "#{@examiner1.title.to_s.mb_chars} #{@examiner1.full_name.mb_chars}"
      pdf.draw_text text, :at=>[x,y], :size=>size

      y = y - 12
      text = "#{@examiner2.title.to_s.mb_chars} #{@examiner2.full_name.mb_chars}"
      pdf.draw_text text, :at=>[x,y], :size=>size

      y = y - 12
      text = "#{@examiner3.title.to_s.mb_chars} #{@examiner3.full_name.mb_chars}"
      pdf.draw_text text, :at=>[x,y], :size=>size
    end

    text = ""
    if @level.to_i.eql? 2
      text = "#{@examiner4.title.to_s.mb_chars} #{@examiner4.full_name.mb_chars}"
    end

    y = y - 12
    pdf.draw_text text, :at=>[x,y], :size=>size

    if @level.to_i.eql? 2
      text = "#{@examiner5.title.to_s.mb_chars} #{@examiner5.full_name.mb_chars}"
    end

    y = y - 12
    pdf.draw_text text, :at=>[x,y], :size=>size

    ##  SET TEXT
    x = 235
    y = y - 5
    w = 380
    h = 30

    l = 0
    if @level.to_i.eql? 1
      y = y + 17
    elsif @level.to_i.eql? 2
      y = y - 5
    end

    pdf.bounding_box [x,y],:width => w, :height=> h,:kerning=>true do
      #pdf.stroke_bounds
      text = "Bajo la presidencia del primero y con carácter de secretario\nel último, para proceder a efectuar la evaluación de la tesis:"
      pdf.text text, :size=> size, :align=> :left, :leading=>l,:character_spacing=>0.0
    end
 
    ## SET THESIS TITLE
    x = 180
    y = y - 30
    w = 400
    h = 40
    size  = 14
    text = math_format(@thesis.title)
    text = "\"#{text}\""

    if text.size >= 110 && text.size <= 165
      size = 12
    elsif text.size > 165 && text.size <= 220
      size = 10
    elsif text.size > 220
      size = 9
    end

    if @level.to_i.eql? 1
      y = y + 5
    end
    pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center ,:inline_format => true

    x = x + 20
    y = y - 47
    size = 12
    grado = @thesis.student.program.name.mb_chars
    first_word = ""
    rest_of_words = ""
    a = grado.split(/ /)
    a.each_with_index do |g,i|
      if grado.size>55
        if i<=2
          first_word = "#{first_word} #{g}"
        else
          rest_of_words = "#{rest_of_words} #{g}"
        end
      else
        if i.eql? 0
          first_word = g
        else
          rest_of_words = "#{rest_of_words} #{g}"
        end
      end
    end

    if @thesis.student.program.id.eql? 9
      w = w - 6
      h = h + 12
      if @rectangles then pdf.stroke_rectangle [x,y], w, h end
      pdf.bounding_box [x,y],:width => w, :height=> h,:kerning=>true do
        pdf.text "Una vez cubiertos los requisitos establecidos en el plan \nde estudios vigente, para obtener el grado de\n  Maestría en Ciencias en Comercialización de la Ciencia y la Tecnología,\n que sustenta:", :size=> size, :align=> :center
      end
    else
      if @rectangles then pdf.stroke_rectangle [x,y], w, h end
      pdf.bounding_box [x,y],:width => w, :height=> h,:kerning=>true do
        pdf.text "Una vez cubiertos los requisitos establecidos en el plan \nde estudios vigente, para obtener el grado de\n #{first_word}#{rest_of_words}, que sustenta:", :size=> size , :align=> :center
      end
    end

  
    ## STUDENT NAME
    student_name = @thesis.student.full_name.mb_chars
    x = 200
    y = y - 45
    w = 395
    h = 16
    s_size = 17
    if student_name.size >= 40
      s_size = 16
    end

    if @thesis.student.program.id.eql? 9
      y = y - 15
    end

    #@rectangles = false
    if @rectangles then pdf.stroke_rectangle [x,y], w, h end
    pdf.text_box student_name, :at=>[x,y], :width=>w, :height=>h, :size=>s_size, :align=> :center, :valign=> :center, :style=>:bold
    
    ## MORE TEXT
    x = 200
    y = y - 30
    w = 400
    h = 40
    size = 12
    pdf.bounding_box [x,y],:width => w, :height=> h,:kerning=>true do
      pdf.text "Los miembros del jurado examinaron al sustentante y\n después de deliberar reservada y libremente entre sí,\n resolvieron declararlo(a)", :size=> size, :align=> :center
    end
    
    ## MORE MORE TEXT
    x = 200
    y = y - 50
    w = 400
    h = 40
    size = 12
    pdf.bounding_box [x,y],:width => w, :height=> h,:kerning=>true do
      pdf.text "\n El Secretario informó al sustentante del resultado\ny el Presidente procedió a tomar la protesta de ley.", :size=> size, :align=> :center
    end

    # SET PRESIDENT SIGN
    x    = -20 #5
    y    = 255
    w    = 280 #225
    h    = 30
    size = 12
    text = "#{@examiner1.title.to_s.mb_chars} #{@examiner1.full_name.mb_chars}\nPresidente"
    pdf.line_width = 0.1
    pdf.stroke_horizontal_line 45,190,:at=>257 
    pdf.text_box text, :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center

    #SET SECRETARY SIGN
    x = 317
    y = 255
    w = 225
    h = 30
    if  @level.to_i.eql? 1
      text = "#{@examiner3.title.to_s.mb_chars} #{@examiner3.full_name.mb_chars}\nSecretario"
    elsif @level.to_i.eql? 2
      text = "#{@examiner5.title.to_s.mb_chars} #{@examiner5.full_name.mb_chars}\nSecretario"
    end
    pdf.stroke_horizontal_line 357,502,:at=> 257
    pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center

    # SET  THIRD VOCAL
    if @level.to_i.eql? 1 #Maestria
      x = 153
      y = 135
      w = 225
      h =  70
    elsif @level.to_i.eql? 2 #Doctorado
      x = 170
      y = 140
      w = 225
      h = 30
      text = "#{@examiner4.title.to_s.mb_chars} #{@examiner4.full_name.mb_chars}\n3er. Vocal"
      pdf.stroke_horizontal_line 210,356,:at=> 141
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
    end
    
    # SET SECOND VOCAL
    if @level.to_i.eql? 1 #Maestria
      x = 307
      y = 168
      w = 225
      h = 115
    elsif  @level.to_i.eql? 2 #Doctorado
      x = 307
      y = 182
      w = 250
      h = 30
      text = "#{@examiner3.title.to_s.mb_chars} #{@examiner3.full_name.mb_chars}\n2do. Vocal"
      pdf.stroke_horizontal_line 357,502,:at=>183
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
    end
    
    # SET FIRST VOCAL
    if @level.to_i.eql? 1 #Maestria
      x    = 170 
      y    = 180
      w    = 225
      h    = 70
      text = "#{@examiner2.title.to_s.mb_chars} #{@examiner2.full_name.mb_chars}\n1er. Vocal"
      pdf.stroke_horizontal_line 210,356,:at=> 183
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :top
    elsif @level.to_i.eql? 2 #Doctorado
      x    = 5
      y    = 182
      w    = 225
      h    = 30
      text = "#{@examiner2.title.to_s.mb_chars} #{@examiner2.full_name.mb_chars}\n1er. Vocal"
      pdf.stroke_horizontal_line 45,190,:at=>183
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
    end

    # SET Vo. Bo.
    if @level.to_i.eql? 1 ## Master
      x = 202
      y = 140
      w = 160
      h = 40
    elsif @level.to_i.eql? 2 ## Doctor
      x = 200
      y = 110
      w = 160
      h = 40
    end
 
    if params[:sign]
      pdf.text_box "Vo. Bo." , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
    end

    # SET CIMAV DIRECTOR
    if params[:sign]
      x     = 202
      y     = 57
      dir   = t(:directory)
      title = dir[:general_director][:title].mb_chars
      name  = dir[:general_director][:name].mb_chars
      job   = dir[:general_director][:job].mb_chars
      text  = "#{title} #{name}\n#{job}"
      pdf.stroke_horizontal_line 210,356,:at=>y + 3
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :top
    end

    # RENDER
    send_data pdf.render, type: "application/pdf", disposition: "inline", filename: "constancia-grado-#{@thesis.student.id}.pdf"
  end ## def grade_certificates

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
      w = 350
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

      if tcss.size > 11
        # CODE INITIAL DATA
        x = 64
        y = 210
        w = 20
        h = 9
        size = 6
        # COURSE NAME INITIAL DATA
        x_1 = 117
        y_1 = 216
        w_1 = 106
        h_1 = 25
        size_1 = 6
        # TERMS INITIAL DATA
        x_2 = 229
        y_2 = 211
        w_2 = 45
        h_2 = 9
        size_2 = 5
        # GRADE INITIAL DATA
        x_3 = 285
        y_3 = 210
        w_3 = 38
        h_3 = 9
        size_3 = 6
        # GRADE ON TEXT INITIAL DATA
        x_4 = 329
        y_4 = 215
        w_4 = 84
        h_4 = 18
        size_4 = 6
      end


        tcss.each do |tcs|
          counter= counter + 1
          ## SET CODE
          text= tcs.term_course.course.code

          pdf.fill_color "ffffff"
          pdf.fill_rectangle [x,y], w, h
          pdf.fill_color "000000"
          pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center

          ## SET INTERLINE SPACE
          if tcss.size > 11
            y = y - 30
          else
            y = y - 50
          end

          ## SET COURSE NAME
          text= tcs.term_course.course.name.mb_chars.upcase

          pdf.fill_color "ffffff"
          pdf.fill_rectangle [x_1,y_1], w_1, h_1
          pdf.fill_color "000000"

          if tcs.term_course.course.name.size > 52
            y_1 = y_1 + 10
            h_1 = h_1 + 20
          elsif  tcs.term_course.course.name.size > 36
            y_1 = y_1 + 5
            h_1 = h_1 + 10
          end

          pdf.text_box text , :at=>[x_1,y_1], :width => w_1, :height=> h_1, :size=>size_1, :style=> :bold, :align=> :center, :valign=> :center
          if tcss.size > 11
            y_1 = y_1 - 30
          else
            y_1 = y_1 - 50
          end

          if tcs.term_course.course.name.size > 52
            y_1 = y_1 - 10
            h_1 = h_1 - 20
          elsif  tcs.term_course.course.name.size > 36
            y_1 = y_1 - 5
            h_1 = h_1 - 10
          end


          ## SET TERM
          term = tcs.term_course.term.name
          year = term.at(2..3)
          subterm = term.at(5)

          text = "#{year}/#{subterm}"
          pdf.fill_color "ffffff"
          pdf.fill_rectangle [x_2,y_2], w_2, h_2
          pdf.fill_color "000000"
          pdf.text_box text , :at=>[x_2,y_2], :width => w_2, :height=> h_2, :size=>size_2, :style=> :bold, :align=> :center, :valign=> :center
          if tcss.size > 11
            y_2 = y_2 - 30
          else
            y_2 = y_2 - 50
          end

          ## SET GRADE
          text = tcs.grade.to_s
          pdf.fill_color "ffffff"
          pdf.fill_rectangle [x_3,y_3], w_3, h_3
          pdf.fill_color "000000"
          pdf.text_box text , :at=>[x_3,y_3], :width => w_3, :height=> h_3, :size=>size_3, :style=> :bold, :align=> :center, :valign=> :center
          if tcss.size > 11
            y_3 = y_3 - 30
          else
            y_3 = y_3 - 50
          end

          ## SET GRADE ON TEXT
          text = get_cardinal_name(tcs.grade.to_i)
          pdf.fill_color "ffffff"
          pdf.fill_rectangle [x_4,y_4], w_4, h_4
          pdf.fill_color "000000"
          pdf.text_box text.upcase , :at=>[x_4,y_4], :width => w_4, :height=> h_4, :size=>size_4, :style=> :bold, :align=> :center, :valign=> :center
          if tcss.size > 11
            y_4 = y_4 - 30
          else
            y_4 = y_4 - 50
          end

          #### GO TO PAGE 2
          if tcss.size > 11
            if counter == 5
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

          else
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
      end

      pdf.font "Times"
      # COUNTER COURSES
      pdf.go_to_page(2)
      x = 260
      y = 168
      w =  6
      h =  9
      size = 9
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "000000"
      if counter > 9
        pdf.fill_color "ffffff"
        w = w +230
        pdf.fill_rectangle [x,y], w, h
        pdf.fill_color "000000"
        text = "#{counter} ASIGNATURAS. LA ESCALA DE CALIFICACIONES"

        pdf.stroke_color= "FFFFFF"
        pdf.line_width= 2
        pdf.stroke_line [34,233],[508,233]


        pdf.stroke_color= "000000"
        pdf.line_width= 0.5
        # horizontal line
        pdf.stroke_line [34.6,200],[505.3,200]
        # vertical lines
        pdf.stroke_line [34.7,234],[34.7,200]
        pdf.stroke_line [119.7,234],[119.7,200]
        pdf.stroke_line [227.3,234],[227.3,200]
        pdf.stroke_line [284.1,234],[284.1,200]
        pdf.stroke_line [329.3,234],[329.3,200]
        pdf.stroke_line [414.4,234],[414.4,200]
        pdf.stroke_line [505.2,234],[505.2,200]
      else
        text = "#{tcss.size}"
      end

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

      # SET GENERAL DIRECTOR
      x = 16
      y = 65
      w = 250
      h = 14
      size = 12
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y + 5], w, h + 5
      pdf.fill_color "000000"
      # Load locale config
      dir = t(:directory)
      title = dir[:general_director][:title].mb_chars.upcase
      name = dir[:general_director][:name].mb_chars.upcase
      job  = dir[:general_director][:job]
      text = "#{title} #{name}"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
      # SET APPOINTMENT
      x = 16
      y = 51
      w = 250
      h = 14
      size = 12
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [x,y], w, h
      pdf.fill_color "000000"
      text = "#{job}"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center

      # RENDER
      send_data pdf.render, type: "application/pdf", disposition: "inline"
    end
  end

=begin 
  NOTAS def diploma
  @template_mode - esta variable se activa y desactiva manualmente cuando el usuario solicita machote 
                   hay que elegir un estudiante que sea del programa que necesitamos.
=end
  def diploma
    @template_mode = false ## leer NOTAS arriba ^
    @r_root = Rails.root.to_s
    time    = Time.new
    t       = Thesis.find(params[:thesis_id])
    libro   = params[:libro]
    foja    = params[:foja]
    day     = params[:day]
    month   = params[:month]
    year    = params[:year]
    duplicate = params[:duplicate]

    @rectangles = false

    pdf = Prawn::Document.new(:page_size=>"LETTER",:page_layout=>:landscape)

    pdf.font_families.update("English" => {
      :bold        => "#{@r_root}/private/fonts/English_.ttf",
      :italic      => "#{@r_root}/private/fonts/English_.ttf",
      :bold_italic => "#{@r_root}/private/fonts/English_.ttf",
      :normal      => "#{@r_root}/private/fonts/English_.ttf"
    })

    pdf.font "English"
    pdf.fill_color "373435"

    pdf.stroke_ellipse [72,305],69,103
    pdf.text_box "Fotografía del Alumno\n Tamaño Título", :at=>[35,317], :size=>11, :width=>90,:height=>40, :align=>:center, :valign=>:center

    x_right_top = 709 #700

    if t.student.program.level.to_i.eql? 2
      program_title = /Doctorado/
      if t.student.gender.eql? "F"
        student_title = "Doctora"
      else
        student_title = "Doctor"
      end
    else
       program_title = /Maestr.a/
       if t.student.gender.eql? "F"
         student_title = "Maestra"
       else
         student_title = "Maestro"
       end
    end
    
    ## OTORGA
    size = 28
    w    = 100
    y    = 407 #400
    h    = size
    x    = x_right_top - w
    if @rectangles then pdf.stroke_rectangle [x,y], w, h end
    pdf.text_box "Otorga a:", :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top

    ## NOMBRE DEL ALUMNO
    size = 36
    w = 500
    y = 377 #370
    h = size - 1
    x = x_right_top - w + 8
    if @rectangles then pdf.stroke_rectangle [x,y], w, h end
    if @template_mode
      pdf.text_box "XXXXX XXXXXX", :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top
    else
     pdf.text_box t.student.full_name, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top
    end

    ## EL GRADO DE
    size = 28
    w = 150
    y = 339 #332
    h = size - 1
    x = x_right_top - w
    if @rectangles then pdf.stroke_rectangle [x,y], w, h end
    pdf.text_box "El grado de:", :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top

    ## TITLE
    size = 40
    w = 540
    y = 318 #302
    h = size - 1
    x = x_right_top - w
    if @rectangles then pdf.stroke_rectangle [x,y], w, h end
    text = t.student.program.name.gsub(program_title,student_title)
    if text.size > 50
      size = 22
    elsif text.size > 34
      size = 35
    end
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:center
    
    size = 25
    w = 480 #470
    y = 274 #260
    h = size * 6
    x = x_right_top - w
    if @rectangles then pdf.stroke_rectangle [x,y], w, h end
 
    text = "Por haber cumplido los estudios requeridos conforme a"
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:justify, :valign=>:justify, :character_spacing => 0.65#0.45
    
    y = y - 28
    text = "los Planes y Programas vigentes, según constancias"
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:justify, :valign=>:justify, :character_spacing => 1.1 #0.85
    
    y = y - 28
    text = "que obran en los archivos de esta institución"
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:justify, :valign=>:justify, :character_spacing => 2.8 #2.56

    y = y - 28
    text = "y por haber aprobado el examen de grado reglamentario"
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:justify, :valign=>:justify, :character_spacing => 0.45 #0.18

    y = y - 28

    if @template_mode
      diax = "XX"
      aniox = "XXXX"
      mesx = "XXXX"
    else
      diax  = t.defence_date.day.to_s
      mesx  = get_month_name(t.defence_date.month).capitalize
      aniox = t.defence_date.year.to_s
    end

    if mesx.size.eql? 4
      char_space = 8.2
      if diax.size.eql? 1
        char_space = char_space + 0.85
      end
    elsif mesx.size.eql? 5
      char_space = 9.3 #9.8
      if diax.size.eql? 1
        char_space = char_space + 0.8
      end
    elsif mesx.size.eql? 6
      char_space = 8.4
      if diax.size.eql? 1
        char_space = char_space + 0.7
      end
    elsif mesx.size.eql? 7
      char_space = 7.8
      if diax.size.eql? 1
        char_space = char_space + 0.7
      end
    elsif mesx.size.eql? 9 
      char_space = 6.7
      if diax.size.eql? 1
        char_space = char_space + 0.6
      end
    elsif mesx.size.eql? 10
      char_space = 6.2
      if diax.size.eql? 1
        char_space = char_space + 0.5
      end
    end

    text = "el día #{diax} de #{mesx} de #{aniox}."
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:justify, :valign=>:justify, :character_spacing => char_space

    ## FECHA
    if @template_mode
      diay  = "XX"
      mesy  = "XXXXX"
      anioy = "XXXX"
    else
      diay  = day
      mesy  = get_month_name(month.to_i)
      anioy = year
    end



    size = 22
    x = 8
    y = 40 #50
    h = size
    w = 400
    text = "Chihuahua, Chih., a #{diay} de #{mesy} de #{anioy}"
    if @rectangles then pdf.stroke_rectangle [x,y], w, h end
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:left, :valign=>:top, :character_spacing => - 0.4

    ## FIRMA
    size = 22
    w = 277
    h = size
    y = 38 #50
    x = x_right_top - w - 40
    text = "Dr. Juan Méndez Nonell"
    if @rectangles then pdf.stroke_rectangle [x,y], w, h end
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:center, :valign=>:top
    
    ## TITLE
    #size = 20
    w    = 277
    h    = size
    y    = y - 27 #27
    x    = x_right_top - w - 38
    text = "Director General" 
    if @rectangles then pdf.stroke_rectangle [x,y], w, h end
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:center, :valign=>:top

    pdf.start_new_page

    x_right_top = 715

    ## TEXTO
    size = 22
    w    = 400
    h    = size * 2 + 5
    y    = 525
    x    = x_right_top - w
    text = "El presente Grado\nFue expedido a favor de:"
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top

    ## NOMBRE ALUMNO
    size = 36
    w    = 500
    y    = 475
    x    = x_right_top - w
    if @template_mode
      text = "XXXXXXXXXXXX"
    else
      text = t.student.full_name
    end
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top

    ## TEXTO
    size = 22
    w    = 200
    y    = 437
    x    = x_right_top - w
    text = "Quien cursó los estudios de:"
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top

    ## GRADE/TITLE
    size = 28
    w    = 700 #550
    y    = 412
    x    = x_right_top - w
    text = t.student.program.name
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top
    
    ## TEXTO
    size = 22
    w    = 200
    y    = 382
    x    = x_right_top - w
    text = "Y aprobó mediante Tesis"
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top
    
    ## LIBRO Y FOJA
    size = 22
    w    = 600
    y    = 358
    x    = x_right_top - w
    if @template_mode
      libro = "X"
      foja  = "X"
    end
    text = "El día #{diax} de #{mesx} de #{aniox} quedó registrado en el libro No #{libro} Foja No. #{foja}"
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top
    
    ## FECHA
    size = 22
    y    = 334
    h    = size
    w    = 403
    x    = x_right_top - w
 
    text = "Chihuahua, Chih., a #{diay} de #{mesy} de #{anioy}"
    if @rectangles then pdf.stroke_rectangle [x,y], w, h end
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top

   ## Duplicado
   if duplicate.to_i.eql? 1
     text = "Duplicado"
     pdf.text_box text, :at=>[x,y-22], :size=>15, :width=>w,:height=>h, :align=>:right, :valign=>:top, :character_spacing => - 0.4
   end
   
    ## FIRMA
    size = 22
    w    = 400
    y    = 212
    h    = 45
    x    = x_right_top - w - 2
    text = "Dr. Alejandro López Ortiz\nDirector Académico"
    pdf.text_box text, :at=>[x,y], :size=>size, :width=>w,:height=>h, :align=>:right, :valign=>:top
     
    send_data pdf.render, type: "application/pdf", disposition: "inline", filename: "diploma-#{libro}-#{foja}"
  end ## def diploma

  def substring(filename,regexp,replacestring)
    text = File.read(filename)
    puts = text.gsub(regexp,replacestring)
    File.open(filename, "w") { |file| file << puts }
  end

  def record
    @student = Student.find(params[:id])
    @s_files = StudentFile.where(:student_id=>params[:id]).map{|i| [i.id,i.file_type]}
    render :layout => 'standalone'
  end

  def student_exists
    json = {}

    @fname    = params[:fname] rescue ""
    @lname    = params[:lname] rescue ""
    @curp     = params[:curp] rescue ""
    @name     = "#{@fname} #{@lname}"

    if (!@fname.blank?)&&(!@lname.blank?)
      @student = Student.where("first_name like '%#{@fname}%' AND last_name like '%#{@lname}%' AND status in (1,6)")
    elsif (@fname.blank?)&&(!@lname.blank?)
      @student = Student.where("last_name like '%#{@lname}%' AND status in (1,6)")
    elsif (@lname.blank?)&&(!@fname.blank?)
      @student = Student.where("first_name like '%#{@fname}%' AND status in (1,6)")
    elsif !@curp.blank?
      @student = Student.where("curp like '%#{@curp}%' AND status in (1,6)")
    else
      @student = []
    end

    if @student.size.eql? 0
      json[:message]= "No existe el alumno [#{@name}]"
    else
      @student.each_with_index do |ss,i|
        s    = {}
        s[:name] = ss.full_name
        s[:curp] = ss.curp
        s[:status] = ss.status
        json[i] = s
      end
    end

    render :json => json
  end

  def students_data
    @students = Student.where(:id=>params[:id])
    render :layout => false
  end

  def public_csv
    std = Student.select("card,programs.prefix,programs.name,status,start_date,end_date").joins(:program).where(:status=>[1..6],:programs=>{:level=>[1,2]})

    temp_file = Tempfile.new('estudiantes.csv')
    CSV.open(temp_file,"w") do |csv|
      std.each do |s|
        csv << [s.card,s.prefix,s.name,Student::STATUS[s.status],s.start_date,s.end_date]
      end
    end

    send_file temp_file, filename: 'estudiantes.csv'
  end

  def public
    std = Student.select("card,programs.prefix,programs.name,status,start_date,end_date").joins(:program).where(:status=>[1..6],:programs=>{:level=>[1,2]})
    csv_string = CSV.generate do |csv|
      std.each do |s|
        csv << [s.card,s.prefix,s.name,Student::STATUS[s.status],s.start_date,s.end_date]
      end
    end

    render :text => csv_string
  end


  def enrollments_admin
    @students = Student.where(:status=>6)
  end

  def payments
    render :layout => 'standalone'
  end
  
  def advance_print
    advance = Advance.find(params[:id])
    #background = "#{Rails.root.to_s}/private/prawn_templates/membretada.png"
    #Prawn::Document.new(:background => background, :background_scale=>0.36, :margin=>[150,60,60,60] ) do |pdf|
    estatus = {'C'=>'Concluida','P'=>'Programada','X'=>'Cancelada'}
    Prawn::Document.new(:margin=>[60,60,60,60] ) do |pdf|
      pdf.font_families.update(
          "Montserrat" => { :bold        => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Bold.ttf"),
                            :italic      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Italic.ttf"),
                            :bold_italic => Rails.root.join("app/assets/fonts/montserrat/Montserrat-BoldItalic.ttf"),
                            :normal      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Regular.ttf") })
      pdf.font "Montserrat"
      pdf.font_size 12
      text = "<b>#{Advance::TYPE[advance.advance_type]}</b>\n\n"
      pdf.text text, :inline_format=>true
      pdf.font_size 11
      pdf.text "<b>Alumno:</b> #{advance.student.full_name}\n\n", :inline_format=>true
      pdf.text "<b>Título:</b> #{advance.title}\n\n", :inline_format=>true
      pdf.text "<b>Fecha:</b> #{advance.advance_date.day} de #{get_month_name(advance.advance_date.month)} del #{advance.advance_date.year}\n\n", :inline_format=>true
      pdf.text "<b>Estatus:</b> #{estatus[advance.status]}\n\n", :inline_format=>true
      pdf.text "<b>Comité Tutoral [calificación]:</b>\n", :inline_format=>true
      
      unless advance.tutor1.nil?
        tutor = Staff.find(advance.tutor1)
        pdf.text "#{tutor.full_name rescue "N.D."} #{advance.grade1.blank? ? '[n.d.]': '['+advance.grade1.to_s+']'}", :inline_format=>true
      end
     
      unless advance.tutor2.nil?
        tutor = Staff.find(advance.tutor2)
        pdf.text "#{tutor.full_name rescue "N.D."} #{advance.grade2.blank? ? '[n.d.]': '['+advance.grade2.to_s+']'}", :inline_format=>true
      end
     
      unless advance.tutor3.nil?
        tutor = Staff.find(advance.tutor3)
        pdf.text "#{tutor.full_name rescue "N.D."} #{advance.grade3.blank? ? '[n.d.]': '['+advance.grade3.to_s+']'}", :inline_format=>true
      end
     
      unless advance.tutor4.nil?
        tutor = Staff.find(advance.tutor4)
        pdf.text "#{tutor.full_name rescue "N.D."} #{advance.grade4.blank? ? '[n.d.]': '['+advance.grade4.to_s+']'}", :inline_format=>true
      end
     
      unless advance.tutor5.nil?
        tutor = Staff.find(advance.tutor5)
        pdf.text "#{tutor.full_name rescue "N.D."} #{advance.grade5.blank? ? '[n.d.]': '['+advance.grade5.to_s+']'}", :inline_format=>true
      end
     
      pdf.text "\n\n<b>Notas:</b>", :inline_format=>true
      pdf.text advance.notes, :inline_format=>true

     
      pdf.number_pages "Página <page> de <total>", {:at=>[0, 0],:align=>:right,:size=>8}
      filename = "avance-#{advance.id}.pdf"
      send_data pdf.render, filename: filename, type: "application/pdf", disposition: "inline"
    end #Prawn
  end
     
     
private
  def auth_digest
    authenticate_or_request_with_http_digest(REALM) do |username|
      USERS[username]
    end
  end

  def generate_certificate(options)
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
    @consecutivo = get_consecutive(@student, time, options[:cert_type])
    @city =
    @rails_root  = "#{Rails.root}"
    @year_s      = year[2,4]
    @year        = year
    @days        = time.day.to_s
    @month       = get_month_name(time.month)

    Prawn::Document.new(:background => background, :background_scale=>0.36, :margin=>60 ) do |pdf|
      pdf.font_families.update(
          "Montserrat" => { :bold        => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Bold.ttf"),
                                  :italic      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Italic.ttf"),
                                  :bold_italic => Rails.root.join("app/assets/fonts/montserrat/Montserrat-BoldItalic.ttf"),
                                  :normal      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Regular.ttf") })
      pdf.font "Montserrat"
      pdf.font_size 11
      x = 190 #232
      y = 565 #565
      w = 300
      h = 50
        
      if @rectangles then pdf.stroke_rectangle [x,y], w, h end
      pdf.text_box "<b>Coordinación de estudios de Posgrado</b>\nNo° de Oficio  PO - #{@consecutivo}/#{@year}\n#{options[:city]}, a #{@days} de #{@month} de #{@year}", :inline_format=>true, :at=>[x,y], :align=>:right ,:valign=>:top, :width=>w, :height=>h

      pdf.font_size 12
      y = y - 80
      x = 10
      h = 50

      if @rectangles then pdf.stroke_rectangle [x,y], w, h end
      pdf.text_box "A quien corresponda\nPresente:", :at=>[x,y], :align=>:left,:valign=>:top, :width=>w, :height=>h,:inline_format=>true

      y = y - 60
      h = 220
      w = 480

      if @rectangles then pdf.stroke_rectangle [x,y], w, h end

      if !(options[:cert_type].in? [Certificate::SOCIAL_WELFARE, Certificate::CREDITS])
        if @op_asesor.eql? 1
          @extra = ", bajo la supervisión académica de"
          s = Staff.find(@student.supervisor).full_name rescue ""
          @point = "#{@extra} <b>#{s}</b>."
        else
          @point = "."
        end
      end

      if options[:cert_type].eql? Certificate::AVERAGE
        @point = @point[0..(@point.size-2)]
        @point = "#{@point} y tiene un promedio general de #{options[:average]}."
      end
      
      if options[:cert_type].eql? Certificate::SEMESTER_AVERAGE
        @point = @point[0..(@point.size-2)]
        @point = "#{@point}y con un promedio semestral de #{options[:average]} en el último semestre cursado <b>#{options[:last_semester]}</b>."
      end

      @extension   = "\n\nSe extiende la presente constancia a petición del interesado para los fines legales a que haya lugar."

      if @rectangles then pdf.stroke_rectangle [x,y], w, h end
      pdf.text_box "#{options[:text]}#{@point}#{@extension}", :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true

      if options[:cert_type] == Certificate::VISA 
        @student_image_uri = @student.image_url.to_s
        
        x = x + 150
        y = y - 222
        w = w - 150
        h = 155
        @atentamente = "\n<b>A t e n t a m e n t e\n\n\n\n#{@firma}\n#{@puesto}</b>"
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box @atentamente, :at=>[x,y], :align=>:center,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
 
        x = x -150
        w = 150
        h = 155
        if @rectangles then pdf.stroke_rectangle [x,y+20], w, h end
        pdf.bounding_box [x,y+20],:width=>w,:height=>h do
          pdf.image "#{@rails_root}/public#{@student_image_uri}", :position=>:left,:width=>w,:height=>h
        end
      else
        y = y - 222 #202
        h = 155
        @atentamente = "\n<b>A t e n t a m e n t e\n\n\n\n#{@firma}\n#{@puesto}</b>"
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box @atentamente, :at=>[x,y], :align=>:center,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
      end

      filename = options[:filename]
      send_data pdf.render, filename: filename, type: "application/pdf", disposition: "inline"
      #send_data pdf.render, filename: filename, type: "application/pdf", disposition: "inline"
    end
  end


  def math_format(text)
   # El símbolo ^ es el unicode 5E
   text = text.gsub(/\^([\u{0000}-\u{005D}\u{006F}-\u{FFFF}]+)\^/) {"<sup>#{$1}</sup>"}
   # El símbolo ¬ es el unicode AC
   text.gsub(/\¬([\u{0000}-\u{00AB}\u{00AD}-\u{FFFF}]+)\¬/) {"<sub>#{$1}</sub>"}
  end
       
  
end
