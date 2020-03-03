# coding: utf-8
class InternshipFilesController < ApplicationController
  before_filter :auth_required, :except=>[:download,:applicant_destroy]
  respond_to :html, :xml, :json

  def destroy
    flash = {}
    @internship_file = InternshipFile.find(params[:id])
    if @internship_file.destroy
      flash[:notice] = "Archivo eliminado"
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Deleted internship_file: #{@internship_file.id},#{@internship_file.description}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else
            redirect_to @internship_file
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
            redirect_to @internship_file
          end
        end
      end
    end

  end

  def update
    flash = {}
    @internship_file = InternshipFile.find(params[:id])

    if @internship_file.update_attributes(params[:internship_file])
      flash[:notice] = "Descripci?n actualizada."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update internship_file: #{@internship_file.id},#{@internship_file.description}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:id] = params[:id]
            json[:newdesc] = params[:internship_file][:description]
            render :json => json
          else
            redirect_to @internship_file
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
            json[:newdesc] = params[:internship_file][:description]
            json[:errors] = @internship_file.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @internship_file
          end
        end
      end
    end
  end
  
  def download
    af = InternshipFile.find(params[:id]).file
    if params[:disposition].eql?'inline'
      send_file af.to_s, disposition: :inline
    else
      send_file af.to_s, :x_sendfile=>true
    end
  end
  
  def applicant_destroy
    @internship_files = InternshipFile.find(params[:id])
    if @internship_files.destroy
      render :inline => "<status>1</status><reference>destroy</reference>"
    else
      render :inline => "<status>0</status><reference>destroy</reference><errors>#{@internship_file.errors.full_messages}</errors>"
    end
  end

end
