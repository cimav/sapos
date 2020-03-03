class EnrollmentFilesController < ApplicationController
   respond_to :html, :xml, :json
 
   def download
    ef = EnrollmentFile.find(params[:id]).file
    if params[:disposition].eql?'inline'
      send_file ef.to_s, disposition: :inline
    else
      send_file ef.to_s, :x_sendfile=>true
    end
  end
  
  def cvu_destroy
    @ef = EnrollmentFile.find(params[:id])
    if @ef.destroy
      render :inline => "<status>1</status><reference>destroy</reference>"
    else
      render :inline => "<status>0</status><reference>destroy</reference><errors>#{@ef.errors.full_messages}</errors>"
    end
  end

end
