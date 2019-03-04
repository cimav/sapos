# coding: utf-8
namespace :summer do
  desc "CIMAV Summertime tasks"

  ############################################################################################################################
  ############################################################################################################################
  task :check => :environment do
  
    Internship.where(:applicant_status=>99).each do |p|
      puts "#{p.id} #{p.full_name}"
      puts "##### files #####"
      InternshipFile.where(:internship_id=>p.id).each do |i_f|
        puts "#{i_f.id} #{i_f.description} #{InternshipFile::REQUESTED_DOCUMENTS[i_f.file_type]}"
      end#InternshipFile
     
      puts "##### tokens #####"
      Token.where(:attachable_id=>p.id,:attachable_type=>p.class,:status=>1).each do |t|
        puts "#{t.id} #{t.token} #{t.expires} #{t.status}"
      end #Tokens
     
      puts "##### contacts #####"
      p.contacts.each do |c|
         puts "#{c.id} #{c.created_at}"
      end
     
    end #Internship.where
  end #task check
 
  task :clean => :environment do 
    Internship.where(:applicant_status=>99).each do |p|
      puts "#{p.id} #{p.full_name}"
      InternshipFile.where(:internship_id=>p.id).each do |i_f|
        puts "##### #{i_f.id} #{i_f.file.to_s} #{i_f.file.to_s}"

        if File.exist?(i_f.file.to_s)
          if File.delete(i_f.file.to_s)
            #i_f.file.remove!
            InternshipFile.find(i_f.id).destroy
            puts "Archivo eliminado" 
          else
            puts "Error al eliminar archivo #{i_f.file}"
          end
          
        else
         puts "No se encontró el archivo #{i_f.file}" 
        end

      end#InternshipFile
     
     
      Token.where(:attachable_id=>p.id,:attachable_type=>p.class,:status=>1).delete_all
      p.destroy
    end #pendings each
   
  end #task clean

end #namespace
