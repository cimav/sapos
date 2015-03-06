class SystemMailer < ActionMailer::Base
  default :from  => "atencion.posgrado@cimav.edu.mx"
  def notification_email(object)
    hash       = eval object.content
    @full_name = hash[:full_name]
    @email     = hash[:email]
    @to        = object.to
    @view      = hash[:view]
    @reply_to  = hash[:reply_to] rescue ""
    @uri       = hash[:uri] rescue ""
    @text      = hash[:text] rescue ""

  if @reply_to.empty?
    mail(:to=> @to,:subject=>object.subject)
  else
    mail(:to=> @to,:subject=>object.subject,:reply_to=>@reply_to)
  end
 end
end
