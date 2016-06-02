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
end ## namespace
