class LogsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
    if current_user.access == User::OPERATOR
      @logs =  ActivityLog.where(:user_id=>current_user.id).limit(10).order('updated_at desc')
    elsif current_user.access == User::ADMINISTRATOR
      @logs =  ActivityLog.limit(10).order('updated_at desc')
    end

    render :layout => false
  end
end
