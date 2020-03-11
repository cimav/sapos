namespace :mailpoll do 
  desc "Envio de encuestas de graduados"
  task :send => :environment do
    students = Student.where("card IN (SELECT c FROM grad2020)")
    c = 0
    students.each do |student|
      poll = GraduatedPoll2020.find_by_student_id(student.id)
      if poll.sent_date.blank?
        c = c + 1
        puts "[#{c}] Sending email to #{student.email}"
        GraduatedPollMailer.poll_mail(student).deliver
        poll.sent_date = Time.now
        poll.save
        sleep(10)
      end
    end
  end
end
