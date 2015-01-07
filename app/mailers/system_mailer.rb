class SystemMailer < ActionMailer::Base
 default :from  => "atencion.posgrado@cimav.edu.mx"
 def notification_email(object)
   hash       = eval object.content
   @full_name = hash[:full_name]
   @email     = hash[:email]
   @to        = object.to
   mail(:to=> @to,:subject=>object.subject)
 end 
end

