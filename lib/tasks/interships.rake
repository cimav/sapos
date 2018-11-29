# coding: utf-8
namespace :internships do
  task :notification => :environment do
    date       = Date.new(2018,10,31)
    interships = Internship.where(:end_date=> date)
    
    interships.each do |i|
      puts i.email
      to      = "enrique.turcott.81@gmail.com" #i.email
      subject = "Documentación para expedir carta de liberación"
      content = "{:full_name=>\"#{i.full_name}\",:usuario=>\"#{i.id}\", :password=>\"#{i.password}\", :view=>28}"
      Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>to,:subject=>subject,:content=>content,:status=>0}).save
    end

    puts interships.size
  end
end
