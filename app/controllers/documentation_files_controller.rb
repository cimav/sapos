class DocumentationFilesController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def destroy
    flash = {}
    @documentation_file = DocumentationFile.find(params[:id])
    if @documentation_file.destroy
      flash[:notice] = "Archivo eliminado"
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Delete Documentation File: #{@documentation_file.id},#{@documentation_file.description}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else
            redirect_to @documentation_file
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
            redirect_to @documentation_file
          end
        end
      end
    end

  end

  def update
    flash = {}
    @documentation_file = DocumentationFile.find(params[:id])

    if @documentation_file.update_attributes(params[:student_file])
      flash[:notice] = "Descripcion actualizada."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Documentation File: #{@documentation_file.id},#{@documentation_file.description}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:id] = params[:id]
            json[:newdesc] = params[:documentation_file][:description]
            render :json => json
          else
            redirect_to @documentation_file
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
            json[:newdesc] = params[:documentation_file][:description]
            json[:errors] = @documentation_file.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @documentation_file
          end
        end
      end
    end
  end
end
  


