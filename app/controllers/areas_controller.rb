# coding: utf-8
class AreasController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
    @remote_id  = params[:area_id]
    @areas      = Area.all
    @area_types = Area::TYPE.invert.sort {|a,b| a[1] <=> b[1] }
    @area_types[0][0] = "Todos los tipos de area"
  end

  def live_search
    c = {}    #conditions hash
    if !params[:area_type].to_i.eql? 0
      c[:area_type]= params[:area_type]
    end
    
    ## texto recibido
    text = params[:q]
    if text.blank?
      @areas = Area.where(c)
    else
      if text.to_i.eql? 0
        @areas = Area.where(c).where("name LIKE '%#{text}%'")
      else
        @areas = Area.where(c).where(:id=>text.to_i)
      end
    end

    render :layout => false
  end

  def show
    @area = Area.find(params[:id])
    render :layout => false
  end

  def new
    @area = Area.new
    render :layout => false
  end

  def create
    flash = {}
    @area  = Area.new(params[:area])

    if @area.save
      flash[:notice] = "Area creada."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Create Area: #{@area.id},#{@area.name}"}).save

      respond_with do |format|
	format.html do
	  if request.xhr?
	    json = {}
	    json[:flash] = flash
            json[:uniq]  = @area.id
	    render :json => json
	  else 
	    redirect_to @area
	  end
	end
      end
    else
      flash[:error] = "Error al crear estudiante."
      @area.errors[:area_type][0] ="Tienes que elegir un tipo"
      respond_with do |format|
	format.html do
	  if request.xhr?
	    json = {}
	    json[:flash]       = flash
	    json[:errors]      = @area.errors
	    json[:errors_full] = @area.errors.full_messages
	    render :json => json, :status => :unprocessable_entity
	  else
	    redirect_to @area
	  end
	end
      end
    end

  end #def create
 
  def update
    flash = {}
    @area = Area.find(params[:id])

    if @area.update_attributes(params[:area])
      flash[:notice] = "Area actualizada."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Area: #{@area.id},#{@area.name}"}).save
      respond_with do |format|
	format.html do
	  if request.xhr?
	    json = {}
	    json[:flash] = flash
	    render :json => json
	  else 
	    redirect_to @area
	  end
	end
      end
    else
      flash[:error] = "Error al actualizar area."
      respond_with do |format|
	format.html do
	  if request.xhr?
	    json = {}
	    json[:flash] = flash
	    json[:errors] = @area.errors
	    json[:errors_full] = @area.errors.full_messages
	    render :json => json, :status => :unprocessable_entity
	  else 
	    redirect_to @area
	  end
	end
      end
    end
  end #def update
end #class
