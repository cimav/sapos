class ScholarshipController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
  end

  def new
    @scholarship = Scholarship.new(params[:scholarship])
    @student_id  = params[:id]
    @full_messages = params[:full_messages]
    if @full_messages.nil?
      @full_messages= "[]"
    end
    render :layout => 'standalone'
  end

  def create
    flash = {}
    @student     = Student.find(params[:student_id])
    params[:scholarship][:student_id] = @student.id
    @scholarship = Scholarship.new(params[:scholarship])
    if @scholarship.save
      @notice = "Nueva beca creada"
    else
      @error = "Error al crear la beca"
      @full_messages = @scholarship.errors.to_json
      redirect_to :action => 'new', :id => @student.id, :full_messages => @full_messages, :scholarship=> params[:scholarship]  and return
    end

    render :layout => 'standalone'
  end
end
