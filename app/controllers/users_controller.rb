# coding: utf-8
class UsersController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
  end

  def live_search
    @users = User.order('email')
    if !params[:q].blank?
      @users = @users.where("(email LIKE :n) AND status<>:r", {:n => "%#{params[:q]}%",:r => User::STATUS_SYSTEM})
    end
    render :layout => false
  end

  def show
    @user = User.find(params[:id])
    @areas = Area.order('name')
    @campus = Campus.all
    if @user.program_type != Program::ALL
      @programs = Program.where(:program_type => @user.program_type)
    end

    @permissions_user = PermissionUser.where(:user_id=>params[:id])
    @permissions_areas = (eval @user.areas) rescue []
    render :layout => false
  end

  def new
    @user  = User.new
    render :layout => false
  end

  def create
    flash = {}
    @user = User.new(params[:user])

    if @user.save
      flash[:notice] = "Usuario creado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Create User: #{@user.id},#{@user.email}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @user.email
            render :json => json
          else
            redirect_to @user
          end
        end
      end
    else
      flash[:error] = "Error al crear usuario."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @user.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @user
          end
        end
      end
    end
  end

  def update
    flash  = {}
    @user  = User.find(params[:id])
    @areas = params[:areas]
    if @areas.nil?
      params[:user][:areas]=nil
    else
      params[:user][:areas]= @areas.to_s
    end


    ActivityLog.new({:user_id=>current_user.id,:activity=>"Update User: #{@user.id},#{@user.email}"}).save
    if @user.update_attributes(params[:user])
      flash[:notice] = "Usuario actualizado."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else
            redirect_to @user
          end
        end
      end
    else
      flash[:error] = "Error al actualizar el usuario."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @user.errors
            json[:errors_full] = @program.errors.full_messages
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @user
          end
        end
      end
    end
  end

  def permissions
    @user = User.find(params[:id])
    @type = params[:type]
    @programs = Program.where(:program_type=>@type)
    render :layout => false
  end

  def configuration
    parameters = {}
    config     = {}

    if params[:u_id].to_i.eql? 0
      @user = User.where(:email=>'SYSTEM').first
    else
      @user = User.find(params[:u_id])
    end

    if params[:option].to_i.eql? 1
      config[:applicants] = {:form_status => params[:value]}

      @user.config = config
      @user.save 
    end

    render_message @user,"Configuracion guardada correctamente",parameters
  end
end
