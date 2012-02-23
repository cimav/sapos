# coding: utf-8
class DepartmentsController < ApplicationController
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
    @department = Department.new(params[:department])

    if @department.save
      flash[:notice] = "Departamento creado."

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
	 @department = Department.find(params[:id])
  
		if @department.update_attributes(params[:department])
			flash[:notice] = "Departamento Actualizado"
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
      flsh[:error] = "Error al actualizar departamento."
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
