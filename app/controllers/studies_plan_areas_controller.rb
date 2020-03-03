class StudiesPlanAreasController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json, :csv
  
  def index
  end

  def live_search
    text = params[:q]
    if text.to_i.eql? 0
      @studies_plan_areas = StudiesPlanArea.where("name LIKE '%#{text}%'")
    else
      @studies_plan_areas = StudiesPlanArea.where(:id=>text.to_i)
    end

    render :layout => false
  end

  def show
    @studies_plan_area = StudiesPlanArea.find(params[:id])
    @studies_plans     = StudiesPlan.all
    render :layout => false
  end

  def new
    @studies_plan_area = StudiesPlanArea.new
    @studies_plans     = StudiesPlan.where(:status=>1)
    render :layout=>false
  end

  def create
    parameters = {}
    @studies_plan_area = StudiesPlanArea.new(params[:studies_plan_area])

    if @studies_plan_area.save
      @message = "Area creada correctamente"
      render_message @studies_plan_area,@message,parameters
    else
      @message = "Error al crear el area"
      render_error @studies_plan_area,@message,parameters
    end
  end

  def update
    parameters = {}
    @studies_plan_area = StudiesPlanArea.find(params[:id])

    if @studies_plan_area.update_attributes(params[:studies_plan_area])
      @message = "Area actualizada correctamente"
      render_message @studies_plan_area,@message,parameters
    else
      @message = "Error al actualizar el area"
      render_error @studies_plan_area,@message,parameters
    end
  end

end
