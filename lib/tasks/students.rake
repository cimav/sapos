namespace :students do
  desc "Sincroniza los apellidos de entre applicants y students"
  task :sync_last_names => :environment do

    applicants = Applicant.where("status NOT IN (?)", [Applicant::DELETED, Applicant::DESISTS])
    students_count = 0

    puts 'Actualizando estudiantes:'
    applicants.each do |applicant|
      if applicant.student
        student = applicant.student
        student.last_name = applicant.primary_last_name
        student.last_name2 = applicant.second_last_name
        if student.save
          students_count += 1
        end

        puts "#{student.id} #{student.full_name}"
      end
    end
    puts "Se actualizaron #{students_count} estudiantes"
  end


  desc "Pone el correo de cimav en el campo correcto"
  task :email_cimav => :environment do

    students = Student.where("status NOT IN (?)", [Student::DELETED])
    students_count = 0

    puts 'Actualizando estudiantes:'
    students.each do |student|
      if !student.email.blank?
        if student.email.include? "@cimav.edu.mx"
          student.email_cimav = student.email
          student.email = ""
          if student.save
            students_count += 1
            puts "#{student.id} #{student.full_name}"
          end
        end
      end
    end
    puts "Se actualizaron #{students_count} estudiantes"
  end

end