# coding: utf-8
class StudentFilesController < ApplicationController
  before_filter :auth_required, :except => ["download"]
  respond_to :html, :xml, :json

  def destroy
    flash = {}
    @student_file = StudentFile.find(params[:id])
    if @student_file.destroy
      flash[:notice] = "Archivo eliminado"
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Delete Student File: #{@student_file.id},#{@student_file.description}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else
            redirect_to @student_file
          end
        end
      end
    else
      flash[:error] = "Error al eliminar archivo"
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @student_file
          end
        end
      end
    end

  end
  
  def destroy_file
    @student_file = StudentFile.find(params[:id])
    if @student_file.destroy
      render :inline => "<status>1</status><reference>destroy</reference>"
    else
      render :inline => "<status>0</status><reference>destroy</reference><errors>#{@student_file.errors.full_messages}</errors>"
    end
  end

  def update
    flash = {}
    @student_file = StudentFile.find(params[:id])

    if @student_file.update_attributes(params[:student_file])
      flash[:notice] = "Descripci?n actualizada."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Student File: #{@student_file.id},#{@student_file.description}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:id] = params[:id]
            json[:newdesc] = params[:student_file][:description]
            render :json => json
          else
            redirect_to @student_file
          end
        end
      end
    else
      flash[:error] = "Error al actualizar la descripcion."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:id] = params[:id]
            json[:newdesc] = params[:student_file][:description]
            json[:errors] = @student_file.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @student_file
          end
        end
      end
    end
  end
  
  def  download
    af = StudentFile.find(params[:id]).file
    send_file af.to_s, :x_sendfile=>true
  end

end
