# coding: utf-8
namespace :becas do
  task :put => :environment do
    students = Student.where(:status=>1)
    BecasRemote.connection.execute("DELETE from becas")

    students.each do |s|
      my_curp = s.curp
      if s.curp.nil? 
        my_curp = ""
      end
      
      my_size_curp = s.curp.size rescue 0
      if my_size_curp.eql? 18
        my_curp = s.curp
      else
        my_curp = ""
      end

      beca = BecasRemote.new(:name=>s.full_name,:curp=>my_curp)
      beca.save
    end #students.each
  end #task put
end #namespace :admin
