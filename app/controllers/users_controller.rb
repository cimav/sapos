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
      @users = @users.where("(email LIKE :n)", {:n => "%#{params[:q]}%"}) 
    end
    render :layout => false
  end

  def show
    @user = User.find(params[:id])
    @campus = Campus.all
    @programs = Program.all
    render :layout => false
  end

  def new
    @user = User.new
    render :layout => false
  end

  def create
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
    @user = User.find(params[:id])
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
            render :json => json, :status => :unprocessable_entity
          else 
            redirect_to @user
          end
        end
      end
    end
  end
end
