# coding: utf-8
class DepartmentsController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
  end

  def live_search
    @departments = Department.order('id')
    if !params[:q].blank?
      @departments = @departments.where("(name LIKE :n OR id LIKE :n)", {:n => "%#{params[:q]}%"}) 
    end

    render :layout => false
  end

  def show
    @department = Department.find(params[:id])
    render :layout => false
  end

  def new
    @department = Department.new
    render :layout => false
  end

  def create
    flash = {}
    @department = Department.new(params[:department])

    if @department.save
      flash[:notice] = "Departamento creado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Create Deparment: #{@department.id},#{@department.name}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @department.id
            render :json => json
          else 
            redirect_to @department
          end
        end
      end
    else
      flash[:error] = "Error al crear aula."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @department.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @department
          end
        end
      end
    end
  end

  def update 
    flash = {}
    @department = Department.find(params[:id])

    if @department.update_attributes(params[:department])
      flash[:notice] = "Departamento Actualizado"
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Deparment: #{@department.id},#{@department.name}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @department.errors
            render :json => json
          else
            redirect_to @department
          end
        end
      end
    else
      flash[:error] = "Error al actualizar departamento."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @department.errors
            render :json => json, :status => :unprocessable_entity
          else 
            redirect_to @department
          end
        end
      end
    end
  end
end
