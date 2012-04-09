class InternshipTypesController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
  end

  def live_search
    @internship_types = InternshipType.order('id')
    if !params[:q].blank?
      @internship_types = @internship_types.where("(name LIKE :n OR id LIKE :n)", {:n => "%#{params[:q]}%"}) 
    end

    render :layout => false
  end

  def show
    @internship_type = InternshipType.find(params[:id])
    render :layout => false
  end

  def new
    @internship_type = InternshipType.new
    render :layout => false
  end

  def create
    @internship_type = InternshipType.new(params[:internship_type])

    if @internship_type.save
      flash[:notice] = "Tipo de Servicio creado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Create Internship type: #{@internship_type.id},#{@internship_type.name}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @internship_type.id
            render :json => json
          else 
            redirect_to @internship_type
          end
        end
      end
    else
      flash[:error] = "Error al crear tipo de servicio."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @internship_type.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @internship_type
          end
        end
      end
    end
  end

  def update 
    @internship_type = InternshipType.find(params[:id])

    if @internship_type.update_attributes(params[:internship_type])
      flash[:notice] = "Tipo de servicio actualizado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Internship type: #{@internship_type.id},#{@internship_type.name}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else 
            redirect_to @internship_type
          end
        end
      end
    else
      flash[:error] = "Error al actualizar el tipo de servicio."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @internship_type.errors
            render :json => json, :status => :unprocessable_entity
          else 
            redirect_to @internship_type
          end
        end
      end
    end
  end
end
