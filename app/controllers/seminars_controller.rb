# coding: utf-8
class SeminarsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
    @user = User.find(current_user.id)
    if @user.access.in? [1,5] ## Administrator or Manager
      @supervisors = Staff.where(:status=>0)
    elsif @user.access.in? [2]  ## Operator
      @supervisors = Staff.where(:status=>0,:area_id=>(eval @user.areas))
    else
      render :text => "Usted no tiene permisos para este módulo"
    end
  end

  def live_search
    @user = User.find(current_user.id)

    if @user.access.in? [1,5] ## Administrator or Manager
      @seminars = Advance.where(:advance_type=>3, :status=>'P')
    elsif @user.access.in? [2]  ## Operator
      @seminars = Advance.joins(:student=>:staff_supervisor).where(:advance_type=>3,:status=>'P').where("staffs.area_id=?",(eval @user.areas))
    end

    if !params[:q].blank?
      if params[:q].to_i != 0
        @seminars = @seminars.where("advances.id = ?",params[:q].to_i)
      else
        @seminars = @seminars.joins(:student).where("(CONCAT(first_name,' ',last_name) LIKE :n OR card LIKE :n)", {:n => "%#{params[:q]}%"})
      end
    end
    render :layout => false
  end

  def show
    @advance = Advance.find(params[:id])
    @staffs  = Staff.where(:status=>0)
 
    my_date     = @advance.advance_date.to_s()
    @eadvance   = my_date.split(" ")[0]
    @hour       = my_date.split(" ")[1].split(":")[0] rescue ""
    @minutes    = my_date.split(" ")[1].split(":")[1] rescue ""
    
    my_date     = @advance.advance_date.to_s()
    @ehour      = my_date.split(" ")[1].split(":")[0] rescue ""
    @eminutes   = my_date.split(" ")[1].split(":")[1] rescue ""

    render :layout => false
  end
   
  def new
    @user = User.find(current_user.id)
    if @user.access.in? [1,5] ## Administrator or Manager
      @students= Student.where(:status=>1)
    elsif @user.access.in? [2]  ## Operator
      @students= Student.joins(:staff_supervisor).where(:status=>1).where("staffs.area_id=?",(eval @user.areas))
    end
    render :layout => false
  end

  def advance_data
    @student = Student.find(params[:advance][:student_id])
    @staffs  = Staff.where(:status=>0)
    render :layout => false
  end

  def create
    parameters = {}

    params[:advance][:status]="P"
    
    if !params[:advance][:advance_date].empty?
      date    = params[:advance][:advance_date]
      hour    = params[:session_hour]
      minutes = params[:session_minutes]
 
      params[:advance][:advance_date] = "#{date} #{hour}:#{minutes}:00"
    end

    params[:advance][:title]        = Thesis.find(params[:thesis_id].to_i).title rescue ""

    @advance  = Advance.new(params[:advance])

    if @advance.save
      params = {}

      params[:horario] = traslate_date(@advance.advance_date)

      if !@advance.tutor1.nil?
        staff  = Staff.find(@advance.tutor1) rescue nil
        email  = staff.email rescue ""
        if !email.empty?
          params[:advance_id] = @advance.id
          params[:staff]   = staff
          send_mail(email,params,1)
        else
          logger.info "Email Vacio Tutor1"
        end
      end
 
      if !@advance.tutor2.nil?
        staff  = Staff.find(@advance.tutor2) rescue nil
        email  = staff.email rescue ""
        if !email.empty?
          params[:advance_id] = @advance.id
          params[:staff]   = staff
          send_mail(email,params,1)
        else
          logger.info "Email Vacio Tutor2"
        end
      end

      if !@advance.tutor3.nil?
        staff  = Staff.find(@advance.tutor3) rescue nil
        email  = staff.email rescue ""
        if !email.empty?
          params[:advance_id] = @advance.id
          params[:staff]   = staff
          send_mail(email,params,1)
        else
          logger.info "Email Vacio Tutor3"
        end
      end

      if !@advance.tutor4.nil?
        staff  = Staff.find(@advance.tutor4) rescue nil
        email  = staff.email rescue ""
        if !email.empty?
          params[:advance_id] = @advance.id
          params[:staff]   = staff
          send_mail(email,params,1)
        else
          logger.info "Email Vacio Tutor4"
        end
      end

      if !@advance.tutor5.nil?
        staff  = Staff.find(@advance.tutor5) rescue nil
        email  = staff.email rescue ""
        if !email.empty?
          params[:advance_id] = @advance.id
          params[:staff]   = staff
          send_mail(email,params,1)
        else
          logger.info "Email Vacio Tutor5"
        end
      end

      params[:advance_id] = @advance.id
      params[:student] = @advance.student
      email = @advance.student.email_cimav rescue @advance.student.email
      send_mail(email,params,2)  ## estudiante

      render_message(@advance,"Seminario departamental creado con éxito",parameters)
    else
      if !@advance.errors[:advance_date].empty?
        text = @advance.errors[:advance_date][0]
        @advance.errors[:advance_date].clear
        @advance.errors[:advance_date] = "(Fecha de presentación) #{text}"
      end

      logger.info @advance.errors
      render_error(@advance,"Error al guardar seminario departamental",parameters)
    end
  end

  def traslate_date(date)
    d       = t(:date)
    days    = d[:day_names]
    months  = d[:month_names]

    return "#{days[date.wday]}, #{date.day} de #{months[date.month]} de #{date.year} a las #{date.hour}:#{date.min}"
  end

  def update
    parameters = {}
    @advance = Advance.find(params[:id])
    @message = "Seminario actualizado."
    if @advance.update_attributes(params[:advance])
      render_message @advance,@message,parameters
    else
      render_error @advance, "Error al actualizar estudiante",parameters
    end
  end

  def send_mail(to,params,opc)
    #to     = "enrique.turcott@cimav.edu.mx" #el colado
    if opc.eql? 1
      staff     = params[:staff]
      att_id    = staff.id 
      att_class = staff.class
      subject = "Usted ha sido elegido como tutor de un seminario"
      content = "{:staff_id=>#{staff.id},:advance_id=>#{params[:advance_id]},:horario=>\"#{params[:horario]}\",:view=>16}"
    elsif opc.eql? 2
      student   = params[:student]
      att_id    = student.id 
      att_class = student.class
      subject = "Su seminario de investigación ha sido programado"
      content = "{:horario=>\"#{params[:horario]}\",:advance_id=>#{params[:advance_id]},:view=>21}"
    end
    
    email = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>to,:subject=>subject,:content=>content,:status=>0})
    
    if email.save
      ActivityLog.new({:user_id=>0,:activity=>"{:attachable_id=>#{att_id},:attachable_type=>'#{att_class}', :activity=>'Se manda un correo a #{to}'}"}).save
    else
      ActivityLog.new({:user_id=>0,:activity=>"{:attachable_id=>#{att_id},:attachable_type=>'#{att_class}', :activity=>'Falla al mandar un correo al solicitante'}"}).save
    end
  end
end
