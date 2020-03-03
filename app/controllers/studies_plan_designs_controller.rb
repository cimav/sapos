# coding: utf-8
class StudiesPlanDesignsController < ApplicationController
  respond_to :html, :xml, :json, :csv

  def index
    @designs = StudiesPlanDesign.where(:studies_plan_id=>params[:id]).order(:design_date)
    @studies_plan_id = params[:id]
    render :layout => 'standalone'
  end

  def show

  end

  def new
    @design = StudiesPlanDesign.new
    render :layout => 'standalone'
  end

  def create
    parameters={}
    @design = StudiesPlanDesign.new(params[:studies_plan_design])

    if @design.save
      redirect_to :action=>"index",:id=> @design.studies_plan_id, :register_ok=>true
    else
      render :template => "studies_plan_designs/new",:layout=>'standalone', :locals=>{:sp_id=>@design.studies_plan_id}
    end
  end

  def destroy
    @design = StudiesPlanDesign.find(params[:id])
    sp_id   = @design.studies_plan_id
    @design.destroy
    redirect_to :action=>"index",:id=>sp_id
  end
end
