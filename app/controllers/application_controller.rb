# coding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def authenticated?
    if session[:user_auth].blank?
      user = User.where(:email => session[:user_email], :status => User::STATUS_ACTIVE).first
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

  def to_excel(rows, column_order, sheetname, filename)
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
    book.write "tmp/#{filename}.xls"
    # send_file("tmp/#{filename}.xls", :type=>"application/ms-excel", :x_sendfile=>true)
    send_file "tmp/#{filename}.xls", :x_sendfile=>true
  end
  
  helper_method :current_user

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
