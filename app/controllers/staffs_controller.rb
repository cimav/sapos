# coding: utf-8
class StaffsController < ApplicationController
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

    render :layout => false
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
    @staff = Staff.new(params[:staff])

    if @staff.save
      flash[:notice] = "Docente creado."

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
    @staff = Staff.find(params[:id])

    if @staff.update_attributes(params[:staff])
      flash[:notice] = "Docente actualizado."
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



end
