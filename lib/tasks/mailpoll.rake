namespace :mailpoll do 
  desc "Envio de encuestas de graduados"
  task :send => :environment do
    students = Student.where("id = 1981")
    students.each do |student|
      puts "Sending email to #{student.email}"
      GraduatedPollMailer.poll_mail(student).deliver
    end
  end
end
