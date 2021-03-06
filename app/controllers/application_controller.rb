# coding: utf-8

require 'rails/generators'
require 'toads'

#Dir["lib/**/*.rb"].each do |path|
#   require_dependency  path
#end

class ApplicationController < ActionController::Base
  protect_from_forgery
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def authenticated?
    if session[:user_auth].blank?
      logger.info "############### |#{session[:user_email]}|"
      user = User.where(:email => session[:user_email], :status => User::STATUS_ACTIVE).first
      logger.info "############### |#{user.email rescue "NULL"}|"
      
      session[:user_auth] = user && user.email == session[:user_email]
      if session[:user_auth]
        session[:user_id] = user.id
      end
    else
      session[:user_auth]
    end
  end
  helper_method :authenticated?

  def auth_required
    redirect_to '/login' unless authenticated?
  end


  def xauthenticated?
    #@user = User.where(:email => session[:admin_user], :status => User::STATUS_ACTIVE).first
    #@user && @user.email == session[:admin_user]

    if session[:user_auth].blank?
      user = User.where(:email => session[:admin_user], :status => User::STATUS_ACTIVE).first
      session[:user] = user
      session[:user_auth] = user && user.email == session[:admin_user]
      if session[:user_auth]
        session[:user_id] = user.id
      end
    else
      session[:user_auth]
    end
  end

  helper_method :authenticated?

  def xauth_required
    redirect_to '/auth/admin' unless authenticated?
  end

  def set_current_user
    User.current = current_user
  end

  def to_excel(rows, column_order, sheetname, filename, option = 0)
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => sheetname
    header_format = Spreadsheet::Format.new :color => :black, :weight => :bold
    sheet1.row(0).default_format = header_format

    rownum = 0
    for column in column_order
      sheet1.row(rownum).push column
    end
    for row in rows
      rownum += 1
      for column in column_order
        sheet1.row(rownum).push row[column].nil? ? 'N/A' : row[column]
      end
    end
    t = Time.now
    filename = "#{filename}_#{t.strftime("%Y%m%d%H%M%S")}"
    if option.eql? 1 ## only create
      book.write "tmp/#{filename}.xls"
      return filename
    else
      book.write "tmp/#{filename}.xls"
      # send_file("tmp/#{filename}.xls", :type=>"application/ms-excel", :x_sendfile=>true)
      send_file "tmp/#{filename}.xls", :x_sendfile=>true
    end
  end

  helper_method :current_user
  helper_method :get_month_name

  def get_month_name(number)
    months = ["enero","febrero","marzo","abril","mayo","junio","julio","agosto","septiembre","octubre","noviembre","diciembre"]
    name = months[number - 1]
    return name
  end
 
  helper_method :get_month_name_abbreviated
  def get_month_name_abbreviated(number)
    months = ["ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic"]
    name = months[number - 1]
    return name
  end

  def get_cardinal_name(number)
    cardinals = [
      "cero",
      "uno",
      "dos",
      "tres",
      "cuatro",
      "cinco",
      "seis",
      "siete",
      "ocho",
      "nueve",
      "diez",
      "once",
      "doce",
      "trece",
      "catorce",
      "quince",
      "dieciséis",
      "diecisiete",
      "dieciocho",
      "diecinueve",
      "veinte",
      "veintiuno",
      "veintidós",
      "veintitrés",
      "veinticuatro",
      "veinticinco",
      "veintiseis",
      "veintisiete",
      "veintiocho",
      "veintinueve",
      "treinta",
      "treinta y uno",
      "treinta y dos",
      "treinta y tres",
      "treinta y cuatro",
      "treinta y cinco",
      "treinta y seis",
      "treinta y siete",
      "treinta y ocho",
      "treinta y nueve",
      "cuarenta",
      "cuarenta y uno",
      "cuarenta y dos",
      "cuarenta y tres",
      "cuarenta y cuatro",
      "cuarenta y cinco",
      "cuarenta y seis",
      "cuarenta y siete",
      "cuarenta y ocho",
      "cuarenta y nueve",
      "cincuenta",
      "cincuenta y uno",
      "cincuenta y dos",
      "cincuenta y tres",
      "cincuenta y cuatro",
      "cincuenta y cinco",
      "cincuenta y seis",
      "cincuenta y siete",
      "cincuenta y ocho",
      "cincuenta y nueve",
      "sesenta",
      "sesenta y uno",
      "sesenta y dos",
      "sesenta y tres",
      "sesenta y cuatro",
      "sesenta y cinco",
      "sesenta y seis",
      "sesenta y siete",
      "sesenta y ocho",
      "sesenta y nueve",
      "setenta",
      "setenta y uno",
      "setenta y dos",
      "setenta y tres",
      "setenta y cuatro",
      "setenta y cinco",
      "setenta y seis",
      "setenta y siete",
      "setenta y ocho",
      "setenta y nueve",
      "ochenta",
      "ochenta y uno",
      "ochenta y dos",
      "ochenta y tres",
      "ochenta y cuatro",
      "ochenta y cinco",
      "ochenta y seis",
      "ochenta y siete",
      "ochenta y ocho",
      "ochenta y nueve",
      "noventa",
      "noventa y uno",
      "noventa y dos",
      "noventa y tres",
      "noventa y cuatro",
      "noventa y cinco",
      "noventa y seis",
      "noventa y siete",
      "noventa y ocho",
      "noventa y nueve",
      "cien"]

      name = cardinals[number]
      return name
  end#get_cardinal_name


  def get_areas(u)
    areas= (eval u.areas) rescue []
    return areas
  end
  
  def render_error(object,message,parameters)
    flash = {}
    flash[:error] = message
    respond_with do |format|
      format.html do 
        if request.xhr?
          json = {}
          json[:flash] = flash
          json[:errors] = object.errors
          json[:errors_full] = object.errors.full_messages
          json[:params] = parameters
          render :json => json, :status => :unprocessable_entity
        else
          redirect_to object
        end
      end
    end
  end

  def render_message(object,message,parameters)
    flash = {}
    flash[:notice] = message
    respond_with do |format|
      format.html do
        if request.xhr?
          json = {}
          json[:flash] = flash
          json[:uniq]  = object.id
          json[:params] = parameters
          render :json => json
        else
          redirect_to object
        end
      end
    end
  end

  def send_email(to,subject,content,object)

    logger "SendEmail>>>>>  >>to>#{to} >>subjetc>#{subject} >>content>#{content}"

    mail    = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>to,:subject=>subject,:content=>content,:status=>0})
   
    if mail.save
      mail.status= 0;
      mail.save
    else
      ActivityLog.new({:user_id=>object.id,:activity=>"{:user_object=>'#{object.class}',:activity=>'Error al guardar email <#{to}>'}"}).save
    end
  end

  def serve_image
    case params[:object_type]
      when "student"
        student = Student.find(params[:object_id])
        redirect_to student.image_url
      when "internship"
        internship = Internship.find(params[:object_id])
        redirect_to internship.image_url
      when "staff"
        staff = Staff.find(params[:object_id])
        redirect_to staff.image_url
      else
        render text:'No es posible mostrar imagen'
    end
  end

  private
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  rescue_from CanCan::AccessDenied do |exception|
    flash = {}
    flash[:error] = "Access denied!"
    respond_with do |format|
      format.html do
        if request.xhr?
          json = {}
          json[:flash] = flash
          render :json => json, :status => :unprocessable_entity
        end
      end
    end
  end
end
