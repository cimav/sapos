# coding: utf-8
namespace :admin do
  desc "System Administrator Scripts"
  ADMIN_MAIL        = ""
  task :access, [:id,:s] => :environment do |t,args|
    if args[:s].eql? "student"
      s = Student.find(args[:id])
      puts "Changing access for student #{s.full_name}..."
      s.notes       = s.email_cimav
      s.email_cimav = ADMIN_MAIL
      s.save
    else
      s = Staff.find(args[:id])
      puts "Changing access for academic #{s.full_name}..."
      s.notes = s.email
      s.email = ADMIN_MAIL
      s.save
    end
  end ## task grades

  task :recover, [:id,:s] => :environment do |t,args|
    if args[:s].eql? "student"
      s = Student.find(args[:id])
      puts "Recovering access for student #{s.full_name}..."
      s.email_cimav = s.notes
      s.save
    else
      s = Staff.find(args[:id])
      puts "Recovering access for academic #{s.full_name}..."
      s.email = s.notes
      s.save
    end
  end ## task recover

  task :recover_all, [:s] => :environment do |t,args|
    if args[:s].eql? "student"
      puts "En student"
    else
      s = Staff.where(:email=>ADMIN_MAIL)
      puts s.size
    end
  end # task recover_all

  task :advance => :environment do
    a = Advance.find(1)
    a.tutor1 = 1
    a.tutor2 = 1
    a.tutor3 = 1
    a.tutor4 = 1
    a.tutor5 = 1
    a.save
  end # task insert

  task :protocols => :environment do 
    protocols = Protocol.all
    puts "[#{protocols.size}]"
    counter = 1
    protocols.each do |p|
      puts "#{counter},\"#{p.advance.student.full_name}\",\"#{p.staff.full_name}\",\"#{(p.grade.eql? 1) ? 'Aprobado' : 'No Aprobado'}\""
      counter = counter + 1
    end
  end

  task :desist, [:id] => :environment do |t,args|
    s = Student.find(args[:id])
    puts s.full_name
    puts s.program.name
    puts "Advances: #{s.advance.size}"
    puts "Theses: #{s.thesis}"
    puts "Contacts: #{s.contact}"

    term_students=""
    s.term_students.each do |ts|
      term_students += "#{ts.id},"
    end
    puts "Term Students [#{term_students.chop}]"

    s.term_students.each do |ts|
      puts "Term Course Students[#{ts.id}]: #{ts.term_course_student.size}"
    end
  end ## task desist

  task :get_applicants_id => :environment do 
=begin
  Hace una busqueda por nombres y apellidos de una lista ubicada en un archivo para aspirantes
  El archivo debe estar en la forma: 
      Apellido|Nombre
      Apellido|Nombre
      Apellido|Nombre
         ...  |  ...
         etc  |  etc
=end
    archivo = ""
    counter = 0
    counter_b = 0
    File.open(archivo,'r') do |s|
      while line = s.gets
        #puts line
        full_name = line.split("|")
        first_name = full_name[1].chomp
        last_name  = full_name[0].chomp

        first_name = first_name.gsub(/^\s+/,"")
        first_name = first_name.gsub(/\s+$/,"")

        last_name = last_name.gsub(/^\s+/,"")
        last_name = last_name.gsub(/\s+$/,"")
        
        puts "#{first_name.chomp}|#{last_name.chomp}"
        
        app =  Applicant.where("concat(TRIM(primary_last_name),' ',TRIM(second_last_name)) LIKE :a AND first_name LIKE :b",  {:a => "%#{last_name}%", :b => "%#{first_name}%"}).order(:id).last
        
        if !app.nil?
          puts "-- #{app.full_name} [#{app.id}]" 
          counter_b = counter_b + 1 
        end

        counter = counter + 1
      end # while line
    end #File
    
    puts counter.to_s+" "+counter_b.to_s
  end## end task get_applicants_id
end ## namespace
