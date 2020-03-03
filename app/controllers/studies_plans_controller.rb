# coding: utf-8
class StudiesPlansController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json, :pdf
 
  def index
  end

  def show
    @studies_plan = StudiesPlan.find(params[:id])
    render :layout => "standalone"
  end

  def new
    @studies_plan = StudiesPlan.new
    @program      = Program.find(params[:program_id])
    render :layout => "standalone"
  end

  def create
    parameters = {}
    @studies_plan = StudiesPlan.new(params[:studies_plan])
    #parameters[:student_plan_id] = @studies_plan.id
    if @studies_plan.save
      message = "Plan de Estudios Creado"
      render_message(@studies_plan,message, parameters)
      return
    else
      message = "Error al dar de alta plan de estudios"
      render_error(@studies_plan,message, parameters)
      return
    end
  end

  def update
     parameters = {}
     @studies_plan = StudiesPlan.find(params[:id])
     if @studies_plan.update_attributes(params[:studies_plan])
       message = "Plan de Estudios Modificado"
       render_message(@studies_plan,message, parameters)
       return
     else
       message = "Error al modificar plan de estudios"
       render_error(@studies_plan,message, parameters)
       return
     end
  end

  def combo
    @program = Program.find(params[:program_id])
    render :layout => false
  end
end
