# coding: utf-8
class LaboratoriesController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
  end

  def live_search
    @laboratories = Laboratory.order('code')
    if !params[:q].blank?
      @laboratories = @laboratories.where("(name LIKE :n OR code LIKE :n)", {:n => "%#{params[:q]}%"}) 
    end

    render :layout => false
  end

  def show
    @laboratory = Laboratory.find(params[:id])
    render :layout => false
  end

  def new
    @laboratory = Laboratory.new
    render :layout => false
  end

  def create
    @laboratory = Laboratory.new(params[:laboratory])

    if @laboratory.save
      flash[:notice] = "Laboratorio creado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Create Laboratory: #{@laboratory.id},#{@laboratory.name}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @laboratory.code
            render :json => json
          else 
            redirect_to @laboratory
          end
        end
      end
    else
      flash[:error] = "Error al crear laboratorio."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @laboratory.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @laboratory
          end
        end
      end
    end
  end

  def update 
    @laboratory = Laboratory.find(params[:id])

    if @laboratory.update_attributes(params[:laboratory])
      flash[:notice] = "Laboratorio actualizado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Laboratory: #{@laboratory.id},#{@laboratory.name}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else 
            redirect_to @laboratory
          end
        end
      end
    else
      flash[:error] = "Error al actualizar laboratorio."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @laboratory.errors
            render :json => json, :status => :unprocessable_entity
          else 
            redirect_to @laboratory
          end
        end
      end
    end
  end
end
