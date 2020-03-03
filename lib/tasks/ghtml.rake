# coding: utf-8
namespace :ghtml do
  desc "Generate static html with data"
  task :now => :environment do 
    [{:id=>2,:file=>"dcm.html"},{:id=>4,:file=>"dcta.html"}].each do |x|
      students = Student.joins(:thesis).where(:students=>{:program_id=>x[:id],:deleted=>0}).order("students.start_date DESC")
      file = "#{Rails.root}/public/#{x[:file]}"
      if File.exists?(file)
        puts "Existe, borramos"
        File.delete(file)
      else
        puts "No Existe"
      end
  
      file = File.open(file,"w")
      file.puts "<html><head>"
      file.puts "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
      file.puts "<link rel=\"stylesheet\" type=\"text/css\" href=\"\">"
      file.puts "<meta http-equiv=\"cache-control\" content=\"max-age=0\" />"
      file.puts "<meta http-equiv=\"cache-control\" content=\"no-cache\" />"
      file.puts "<meta http-equiv=\"expires\" content=\"0\" />"
      file.puts "<meta http-equiv=\"expires\" content=\"Tue, 01 Jan 1980 1:00:00 GMT\" />"
      file.puts "<meta http-equiv=\"pragma\" content=\"no-cache\" />"
      file.puts "</head><body>"
      file.puts "<table><thead><tr><th>Matr&iacute;cula</th><th>Estatus</th><th>Fecha de Ingreso</th><th>Tesis</th></tr></thead><tbody>"
      students.each_with_index do |s,i|
        file.puts "<tr><td>#{s.card}</td><td>#{s.status_type}</td><td>#{s.start_date}</td><td>#{s.thesis.title}</td></tr>\n"
      end
     
      file.puts "</tbody></table></body></html>"
      file.puts "Ultima actualizaci&oacute;n: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    end
  end
end
