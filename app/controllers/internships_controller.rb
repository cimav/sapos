# coding: utf-8
class InternshipsController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
    @institutions = Institution.order('name').where("id IN (SELECT DISTINCT institution_id FROM internships)")
    @staffs = Staff.order('first_name').where("id IN (SELECT DISTINCT staff_id FROM internships)")
    @internship_types = InternshipType.order('name')
 
    if current_user.access == User::OPERATOR
      @campus = Campus.order('name').where(:id=> current_user.campus_id)
    else
      @campus = Campus.order('name')
    end 
  end

  def live_search
    if current_user.access == User::OPERATOR
      @internships = Internship.order("first_name").where(:campus_id => current_user.campus_id)
    else    
      @internships = Internship.order("first_name")
    end 

    if params[:institution] != '0' then
      @internships = @internships.where(:institution_id => params[:institution])
    end 

    if params[:staff] != '0' then
      @internships = @internships.where(:staff_id => params[:staff])
    end 

    if params[:internship_type] != '0' then
      @internships = @internships.where(:internship_type_id => params[:internship_type])
    end 

    if !params[:q].blank?
      @internships = @internships.where("(CONCAT(first_name,' ',last_name) LIKE :n OR id LIKE :n)", {:n => "%#{params[:q]}%"}) 
    end

    s = []

    if !params[:status_activos].blank?
      s << params[:status_activos].to_i
    end

    if !params[:status_finalizados].blank?
      s << params[:status_finalizados].to_i
    end

    if !params[:status_inactivos].blank?
      s << params[:status_inactivos].to_i
    end

    if !s.empty?
      @internships = @internships.where("status IN (#{s.join(',')})")
    end

    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.xls do
        rows = Array.new
        @internships.collect do |s|
          rows << {'Nombre' => s.first_name,
                   'Apellidos' => s.last_name,
                   'Sexo' => s.gender,
                   'Email' => s.email,
                   'Fecha Nacimiento' => s.date_of_birth,
                   'Tipo' => s.internship_type.name,
                   'Institucion' => (s.institution.name rescue ''),
                   'Inicio' => s.start_date,
                   'Fin' => s.end_date,
                   'Asesor' => (s.staff.full_name rescue ''),
                   'Tesis' => s.thesis_title,
                   'Actividades' => s.activities
                   }
        end
        column_order = ["Nombre", "Apellidos", "Sexo","Email", "Fecha de Nacimiento", "Tipo", "Institucion", "Inicio", "Fin", "Asesor", "Tesis", "Actividades"]
        to_excel(rows, column_order, "ServiciosCIMAV", "ServiciosCIMAV")
      end
    end

  end

  def show
    @internship = Internship.find(params[:id])
    @countries = Country.order('name')
    @institutions = Institution.order('name')
    @internship_types = InternshipType.order('name')
    @staffs = Staff.order('first_name').includes(:institution)
    @states = State.order('code')

    if current_user.access == User::OPERATOR
      @campus = Campus.order('name').where(:id=> current_user.campus_id)
    else
      @campus = Campus.order('name')
    end 

    render :layout => false
  end

  def new
    @internship = Internship.new
    @institutions = Institution.order('name')
    @internship_types = InternshipType.order('name')
    render :layout => false
  end

  def create
    @internship = Internship.new(params[:internship])

    if @internship.save
      flash[:notice] = "Servicio creado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Create Internship: #{@internship.id},#{@internship.first_name} #{@internship.last_name}"}).save

      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:uniq] = @internship.id
            render :json => json
          else 
            redirect_to @internship
          end
        end
      end
    else
      flash[:error] = "Error al crear becario."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @internship.errors
            render :json => json, :status => :unprocessable_entity
          else
            redirect_to @internship
          end
        end
      end
    end
  end

  def update 
    @internship = Internship.find(params[:id])

    if @internship.update_attributes(params[:internship])
      flash[:notice] = "Servicio actualizado."
      ActivityLog.new({:user_id=>current_user.id,:activity=>"Update Internship: #{@internship.id},#{@internship.first_name} #{@internship.last_name}"}).save
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            render :json => json
          else 
            redirect_to @internship
          end
        end
      end
    else
      flash[:error] = "Error al actualizar al becario."
      respond_with do |format|
        format.html do
          if request.xhr?
            json = {}
            json[:flash] = flash
            json[:errors] = @internship.errors
            render :json => json, :status => :unprocessable_entity
          else 
            redirect_to @internship
          end
        end
      end
    end
  end

  def change_image
    @internship = Internship.find(params[:id])
    render :layout => 'standalone'
  end

  def upload_image
    @internship = Internship.find(params[:id])
    if @internship.update_attributes(params[:internship])
      flash[:notice] = "Imagen actualizada."
    else
      flash[:error] = "Error al actualizar la imagen."
    end

    redirect_to :action => 'change_image', :id => params[:id]
  end

  def files
    @internship = Internship.includes(:internship_file).find(params[:id])
    @internship_file = InternshipFile.new
    render :layout => 'standalone'
  end

  def upload_file
    params[:internship_file]['file'].each do |f|
      @internship_file = InternshipFile.new(f)
      @internship_file.internship_id = params[:internship_file]['internship_id']
      @internship_file.file = f
      @internship_file.description = f.original_filename
      if @internship_file.save
        flash[:notice] = "Archivo subido exitosamente."
      else
        flash[:error] = "Error al subir archivo."
      end
    end

    redirect_to :action => 'files', :id => params[:id]
  end

  def file
    s = Internship.find(params[:id])
    sf = s.internship_file.find(params[:file_id]).file
    send_file sf.to_s, :x_sendfile=>true
  end

  def delete_file
  end


  def id_card
    @internship = Internship.find(params[:id])
    respond_with do |format|
      format.html do
        render :layout => false
      end
      format.pdf do
        @is_pdf = true
        html = render_to_string(:layout => false , :action => "id_card.html.haml")
        kit = PDFKit.new(html, :page_size => 'Legal', :orientation => 'Landscape', :margin_top    => '0',:margin_right  => '0', :margin_bottom => '0', :margin_left   => '0')
        kit.stylesheets << "#{Rails.root}/public/stylesheets/compiled/card.css"
        filename = "INTERN-#{@internship.id}.pdf"
        send_data(kit.to_pdf, :filename => filename, :type => 'application/pdf')
        return # to avoid double render call
      end
    end
  end



end
