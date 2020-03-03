# coding: utf-8
namespace :internships do
  desc "System Administrator Scripts"

  #############################################################################################
  # duplicate
  # Los parametros de entrada deben estar separados por comas y sin espacios, ejemplo: 1,2,3,4
  #############################################################################################
  task :duplicate, [:first]  => :environment do |t,args|
    array = Array.new
    array << args[:first]
    args.extras.each do |e|
      array << e
    end

    internships = Internship.where(:id=>array)
    internships.each do |i|
      puts "#{i.id}|#{i.full_name}"
      
      new_i            = i.dup
      new_i.status     = 0
      new_i.start_date = '2019-09-03'
      new_i.end_date   = '2019-12-13'
      new_i.staff_id   =  50  ## 50 Eduardo Herrera, 68 Luis Lozoya
      new_i.notes      = "Registro duplicado por script"

      if new_i.save(:validate=>false)
        puts "OK!"
      else
        puts "[1]"
        puts new_i.errors.full_messages
      end
    end ## each
  end ## task duplicate

  #############################################################################################
  #  rescue
  # Los parametros de entrada deben estar separados por comas y sin espacios, ejemplo: 1,2,3,4
  #############################################################################################
  task :rescue, [:first] => :environment do |t,args|
    array = Array.new
    array << args[:first]
    args.extras.each do |e|
      array << e
    end
    
    internships = Internship.where(:id=>array)
    internships.each do |i|
      puts "#{i.id}|#{i.full_name}"

      i.status = 0
      i.applicant_status = 3

      if i.save(:validate=>false)
        puts "OK!"
      else
        puts "[1]"
        puts new_i.errors.full_messages
      end
    end
  end ## task rescue
end ## namespace
