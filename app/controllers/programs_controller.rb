# coding: utf-8
class ProgramsController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json, :pdf

  def index
  end

  def live_search
    if current_user.program_type == Program::ALL
      @programs = Program.order('name')
    else
      @programs = Program.joins(:permission_user).where(:permission_users => {:user_id => current_user.id})
    end

    if !params[:q].blank?
      @programs = @programs.where("name LIKE :n OR prefix LIKE :n", {:n => "%#{params[:q]}%"})
    end

    if params[:program_type] != '0' then
      @programs = @programs.where(:program_type => params[:program_type])
    end

    render :layout => false
  end

  def show
    @program = Program.find(params[:id])
    render :layout => false
  end

  def new
    @program = Program.new
    render :layout => false
  end

  def create
    flash = {}
    @program = Program.new(params[:program])

    if @program.save
      flash[:notice] = "Programa creada."
      ActivityLog.new({:user_id => current_user.id, :activity => "Create Program: #{@program.id},#{@program.name}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @program.prefix
            render :json => json
          else
            redirect_to @program
          end
        end
      end
    else
      flash[:error] = "Error al crear programa."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @program.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @program
          end
        end
      end
    end
  end

  def update
    flash = {}
    @program = Program.find(params[:id])
    if @program.update_attributes(params[:program])
      flash[:notice] = "Programa actualizada."
      ActivityLog.new({:user_id => current_user.id, :activity => "Update Program: #{@program.id},#{@program.name}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else
            redirect_to @program
          end
        end
      end
    else
      flash[:error] = "Error al actualizar la programa."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @program.errors
            json[:errors_full] = @program.errors.full_messages
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @program
          end
        end
      end
    end
  end

  def plan_table
    @program = Program.find(params[:id])
    @studies_plan_id = params[:studies_plan_id]
    render :layout => false
  end

  def new_course
    @program = Program.find(params[:id])
    @studies_plan = StudiesPlan.find(params[:studies_plan_id])
    render :layout => 'standalone'
  end

  def create_course
    flash = {}
    @program = Program.find(params[:program_id])
    @studies_plan = StudiesPlan.find(params[:studies_plan_id])
    if @program.update_attributes(params[:program])
      flash[:notice] = "Nuevo curso creado."
    else
      flash[:error] = "Error al crear curso."
    end
    render :layout => 'standalone'
  end

  def edit_course
    @program = Program.find(params[:id])
    @course = Course.find(params[:course_id])
    render :layout => false
  end

  def new_term
    @program = Program.find(params[:id])
    render :layout => 'standalone'
  end

  def create_term
    flash = {}
    @program = Program.find(params[:program_id])
    if @program.update_attributes(params[:program])
      flash[:notice] = "Nuevo curso creado."
    else
      flash[:error] = "Error al crear curso."
    end
    render :layout => 'standalone'
  end

  def edit_term
    @program = Program.find(params[:id])
    @term = Term.find(params[:term_id])
    render :layout => false
  end

  def terms_table
    @program = Program.find(params[:id])
    render :layout => false
  end

  def terms_dropdown
    render :layout => false
  end

  def courses_dropdown
    @term_course = TermCourse.where('term_id = :t', {:t => params[:term_id]}).group('course_id')
    @term = Term.find(params[:term_id])
    render :layout => false
  end


  def enrollment_table
    @term = Term.find(params[:term_id])
    render :layout => false
  end

  def new_enrollment
    @program = Program.find(params[:id])
    @term = Term.find(params[:term_id])
    render :layout => 'standalone'
  end

  def create_enrollment
    flash = {}
    @term = Term.find(params[:term_id])
    if @term.update_attributes(params[:term])
      flash[:notice] = "Estudiante inscrito satisfactoriamente"
    else
      flash[:error] = "Error al inscribir estudiante."
    end
    render :layout => 'standalone'
  end

  def edit_enrollment
    @program = Program.find(params[:id])
    #@ts = TermStudent.includes(:term_student_payment).find(params[:term_student_id])
    @ts = TermStudent.find(params[:term_student_id])
    render :layout => 'standalone'
  end

  def update_enrollment
    flash = {}
    @ts = TermStudent.find(params[:ts][:id])
    if @ts.update_attributes(params[:ts])
      flash[:notice] = "Inscripción actualizada"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else
            redirect_to @ts
          end
        end
      end
    else
      flash[:error] = "Error al actualizar la inscripción"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @cs.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @ts
          end
        end
      end
    end
  end

  def schedule_table
    if !params[:group].blank?
      @tc = TermCourse.where('term_id = :t AND course_id = :c AND `group` = :g', {:t => params[:term_id], :c => params[:course_id], :g => params[:group]}).first
    else
      @tc = TermCourse.where('term_id = :t AND course_id = :c', {:t => params[:term_id], :c => params[:course_id]}).first
      params[:group] = @tc.group
    end
    if @tc
      render :layout => false
    else
      render :inline => 'Error'
    end
  end

  def select_courses_for_term
    @program = Program.find(params[:id])
    @term = Term.find(params[:term_id])
    render :layout => 'standalone'
  end

  def courses_assign
    @program = Program.find(params[:id])
    @studies_plan = StudiesPlan.find(params[:studies_plan_id])
    @term = Term.find(params[:term_id])
    @courses_assigned = TermCourse.where("term_id = :t AND status = :s", {:t => @term.id, :s => TermCourse::ASSIGNED}).collect {|i| i.course_id}
    render :layout => false
  end

  def assign_courses_to_term
    @term = Term.find(params[:term_id])
    if !params[:courses].nil?
      courses = params[:courses].collect {|i| i.to_i}
    else
      courses = []
    end
    @term.assign_courses(courses)
    render :layout => 'standalone'
  end

  def new_schedule
    @program = Program.find(params[:id])

    if !params[:group].blank?
      @tc = TermCourse.where('term_id = :t AND course_id = :c AND `group` = :g', {:t => params[:term_id], :c => params[:course_id], :g => params[:group]}).first
    else
      @tc = TermCourse.where('term_id = :t AND course_id = :c', {:t => params[:term_id], :c => params[:course_id]}).first
      params[:group] = @tc.group
    end

    @staffs = Staff.where(:status=>0).order('institution_id').includes(:institution)
    render :layout => 'standalone'
  end

  def create_schedule
    parameters = {}
    @tc = TermCourse.find(params[:term_course_id])
    program = @tc.course.program

    if @tc.update_attributes(params[:term_course])
      flash[:notice] = "Sesión creada."
      render_message(@tc,"Sesión Creada", parameters)
    else
      render_error(@tc,"Error al dar de alta horario",parameters)
    end#else
  end

  def edit_schedule
    @program = Program.find(params[:id])
    @cs = TermCourseSchedule.find(params[:term_course_schedule_id])
    @staffs = Staff.order('first_name').includes(:institution)
    @institutions = Institution.order('name')
    render :layout => 'standalone'
  end

  def update_schedule
    flash = {}
    @cs = TermCourseSchedule.find(params[:cs][:id])
    if @cs.update_attributes(params[:cs])
      if (@cs.status == TermCourseSchedule::INACTIVE)
        flash[:notice] = "Sesión dada de baja."
      else
        flash[:notice] = "Sesión actualizada."
      end
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:group] = @cs.term_course.group
            render :json => json
          else
            redirect_to @cs
          end
        end
      end
    else
      flash[:error] = "Error al actualizar la sesión"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @cs.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @cs
          end
        end
      end
    end
  end

  def students_table
    @is_pdf = false
    if !params[:group].blank?
      @tc = TermCourse.where('term_id = :t AND course_id = :c AND `group` = :g', {:t => params[:term_id], :c => params[:course_id], :g => params[:group]}).first
    else
      @tc = TermCourse.where('term_id = :t AND course_id = :c', {:t => params[:term_id], :c => params[:course_id]}).first
      params[:group] = @tc.group
    end

    @remaining = @tc.term_course_students.where(:status=>1,:teacher_evaluation=>false).size

    respond_with do |format|
      format.html do
        if @tc
          render :layout => false
        else
          render :inline => 'Error'
        end
      end
      format.pdf do
        if @tc.kind_of?(Array)
          @term_id = @tc[0].course.id
        else
          @term_id = @tc.course.id
        end
        institution = Institution.find(1)
        @logo = institution.image_url(:medium).to_s
        @is_pdf = true
        @today = Time.now
        html = render_to_string(:layout => false, :action => "students_table.html.haml")
        kit = PDFKit.new(html, :page_size => 'Letter')
        kit.stylesheets << "#{Rails.root}#{Sapos::Application::ASSETS_PATH}pdf.css"
        filename = "acta-#{@term_id}.pdf"
        send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        return # to avoid double render call
      end
    end
  end

  def new_course_student
    @program = Program.find(params[:id])
    if !params[:group].blank?
      @tc = TermCourse.where('term_id = :t AND course_id = :c AND `group` = :g', {:t => params[:term_id], :c => params[:course_id], :g => params[:group]}).first
    else
      @tc = TermCourse.where('term_id = :t AND course_id = :c', {:t => params[:term_id], :c => params[:course_id]}).first
      params[:group] = @tc.group
    end
    render :layout => 'standalone'
  end

  def create_course_student
    flash = {}
    @tc = TermCourse.find(params[:term_course_id])
    if @tc.update_attributes(params[:term_course])
      flash[:notice] = "Estudiante agregado."
    else
      flash[:error] = "Error al agregar estudiante."
    end
    render :layout => 'standalone'
  end

  def edit_course_student
    @program = Program.find(params[:id])
    @cs = TermCourseStudent.find(params[:term_course_student_id])
    raise "Programs doesn't match" if @program.id != @cs.term_course.term.program_id
    render :layout => 'standalone'
  end

  def update_course_student
    flash = {}
    @cs = TermCourseStudent.find(params[:cs][:id])
    if @cs.update_attributes(params[:cs])
      flash[:notice] = "Estudiante actualizado."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:group] = @cs.term_course.group
            render :json => json
          else
            redirect_to @cs
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
            json[:errors] = @cs.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @cs
          end
        end
      end
    end
  end

  def inactive_course_student
    flash = {}
    @cs = TermCourseStudent.find(params[:term_course_student_id])
    params[:cs] = {:status => TermCourseStudent::INACTIVE}
    if @cs.update_attributes(params[:cs])
      flash[:notice] = "Estudiante dado de baja."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:group] = @cs.term_course.group
            render :json => json
          else
            redirect_to @cs
          end
        end
      end
    else
      flash[:error] = "Error al desactivar al estudiante."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @cs.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @cs
          end
        end
      end
    end
  end

  def attendee_table
    @is_pdf = false

    if !params[:group].blank?
      @tc = TermCourse.where('term_id = :t AND course_id = :c AND `group` = :g', {:t => params[:term_id], :c => params[:course_id], :g => params[:group]}).first
    else
      @tc = TermCourse.where('term_id = :t AND course_id = :c', {:t => params[:term_id], :c => params[:course_id]}).first
      params[:group] = @tc.group
    end
    if !@tc
      render :inline => 'Error'
    end

    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.pdf do
        @is_pdf = true
        html = render_to_string(:layout => false, :action => "attendee_table.html.haml")
        kit = PDFKit.new(html, :page_size => 'Letter', :orientation => 'Landscape')
        kit.stylesheets << "#{Rails.root}#{Sapos::Application::ASSETS_PATH}pdf.css"
        filename = "asistencia-#{@tc.id}.pdf"
        send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        return # to avoid double render call
      end
    end

  end

  def new_group
    @institutions = Institution.order('name')
    @tc = TermCourse.new
    @tc.term_id = params[:term_id]
    @tc.course_id = params[:course_id]
    render :layout => 'standalone'
  end

  def create_group
    flash = {}
    @tc = TermCourse.new
    if @tc.update_attributes(params[:term_course])
      flash[:notice] = "Grupo creado."
    else
      flash[:error] = "Error al crear grupo."
    end
    render :layout => 'standalone'
  end

  def update_staff_to_group
    @tc = TermCourse.where('term_id = :t AND course_id = :c AND `group` = :g', {:t => params[:term_id], :c => params[:course_id], :g => params[:group]}).first
    render :layout => 'standalone'
  end

  def update_group
    flash = {}
    @tc = TermCourse.find(params[:term_course][:id])
    if @tc.update_attributes(params[:term_course])
      flash[:notice] = "El titular del grupo ha sido actualizado."
    else
      flash[:error] = "Error al cambiar al titular del grupo."
    end
    render :layout => 'standalone'
  end

  def groups_dropdown
    @tc = TermCourse.where('term_id = :t AND course_id = :c', {:t => params[:term_id], :c => params[:course_id]}).first
    render :layout => false
  end

  def documentation
    if !params[:group].blank?
      @tc = TermCourse.where('term_id = :t AND course_id = :c AND `group` = :g', {:t => params[:term_id], :c => params[:course_id], :g => params[:group]}).first
    else
      @tc = TermCourse.where('term_id = :t AND course_id = :c', {:t => params[:term_id], :c => params[:course_id]}).first
      params[:group] = @tc.group
    end
    if !@tc
      render :inline => 'Error'
    end
    render :layout => false
  end

  def files
    @program = Program.includes(:documentation_file).find(params[:id])
    @documentation_file = DocumentationFile.new
    render :layout => 'standalone'
  end

  def upload_file
    flash = {}
    params[:documentation_file]['file'].each do |f|
      @documentation_file = DocumentationFile.new
      @documentation_file.program_id = params[:documentation_file]['program_id']
      @documentation_file.file = f
      @documentation_file.description = f.original_filename
      if @documentation_file.save
        flash[:notice] = "Archivo subido exitosamente."
      else
        flash[:error] = "Error al subir archivo."
      end
    end

    redirect_to :action => 'files', :id => params[:id]
  end

  def file
    p = Program.find(params[:id])
    pf = p.documentation_file.find(params[:file_id]).file
    send_file pf.to_s, :x_sendfile => true
  end

  def delete_file
  end

  def delete_term_course
    term_course = TermCourse.find(params[:term_course_id])
    students = term_course.term_course_students
    if students.where(:status => TermCourseStudent::ACTIVE).size == 0 && students.where(:status => TermCourseStudent::PENROLLMENT).size == 0
      term_course.status = TermCourse::DELETED
      if term_course.save
        ActivityLog.new(user_id:current_user.id, activity:"Eliminar grupo #{term_course.course.name} id: #{term_course.id}").save
        mensaje = "Curso eliminado"
      else
        mensaje = "Error al eliminar curso"
      end
    else
      mensaje = "Hay alumnos inscritos a este grupo"
    end
    render text:mensaje
  end
end


