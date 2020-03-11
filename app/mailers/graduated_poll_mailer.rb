class GraduatedPollMailer < ActionMailer::Base
  default from: "atencion.posgrado@cimav.edu.mx"
 
  def poll_mail(student)
    @student = student
    @url  = "http://posgrado.cimav.edu.mx/encuesta/#{@student.graduated_poll_2020.token}"
    mail(to: @student.email, subject: 'Encuesta Seguimiento de Egresados CIMAV')
  end
end
