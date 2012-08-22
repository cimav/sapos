class StaffFilesController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def destroy
    flash = {}
    @staff_file = StaffFile.find(params[:id])
    if @staff_file.destroy
      flash[:notice] = "Archivo eliminado"
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Delete Staff File: #{@staff_file.id},#{@staff_file.description}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else
            redirect_to @staff_file
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
            redirect_to @staff_file
          end
        end
      end
    end

  end

  def update
    flash = {}
    @staff_file = StaffFile.find(params[:id])

    if @staff_file.update_attributes(params[:staff_file])
      flash[:notice] = "Descripcin actualizada."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Staff File: #{@staff_file.id},#{@staff_file.description}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:id] = params[:id]
            json[:newdesc] = params[:staff_file][:description]
            render :json => json
          else
            redirect_to @staff_file
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
            json[:newdesc] = params[:staff_file][:description]
            json[:errors] = @staff_file.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @staff_file
          end
        end
      end
    end
  end
end
