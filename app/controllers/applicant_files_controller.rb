class ApplicantFilesController < ApplicationController
  before_filter :auth_required, :except=>[:download,:destroy]
  respond_to :html, :xml, :json

  def destroy
    @applicant_files = ApplicantFile.find(params[:id])
    if @applicant_files.destroy
      render :inline => "<status>1</status><reference>destroy</reference>"
    else
      render :inline => "<status>0</status><reference>destroy</reference><errors>#{@applicant_file.errors.full_messages}</errors>"
    end
  end
  
  def  download
    af = ApplicantFile.find(params[:id]).file
    send_file af.to_s, :x_sendfile=>true
  end

  def update

  end
end
