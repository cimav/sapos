# coding: utf-8
namespace :missings_finder do
  desc "Busca registros vacios o faltantes en todo el sistema"
  task :search => :environment do
=begin
    ## supervisor en nulo, campus monterrey, programas academicos y fecha antes de que los ultimos alumnos cursen 2o semestre
    master = Student.select("students.id").joins(:program).where(:campus_id=>2).where("programs.level=1  AND supervisor is null AND students.created_at <'2019-08-01'")
    doctorate = Student.select("students.id").joins(:program).where(:campus_id=>2).where("programs.level=2 AND supervisor is null")
    
    total_students_array = master.to_a + doctorate.to_a

    total_array = []
    total_students_array.each do |ta|
       total_array << ta.id
    end 

    ## buscando otros campos en nulo
    master = Student.

    puts total_array
    puts "Total: #{total_array.size}"
=end
    masters = Student.select("students.id").joins(:program).where(:campus_id=>2).where("programs.level=1 AND students.created_at <'2019-08-01'")
    doctorates = Student.select("students.id").joins(:program).where(:campus_id=>2).where("programs.level=2")
    total_students = masters + doctorates
    total_missings = 0
    missings_array = []
    missings_hash  = {}

    total_students.each do |ts|
      s = Student.find(ts.id)

      if s.supervisor.nil?
        missings_array << "Asesor"
      end
 
      if s.start_date.nil?
        missings_array << "Fecha de inicio"
      end     

      if s.cvu.blank?
        missings_array << "CVU"
      end     

      if s.scholarship_type.nil?
        missings_array << "Tipo de beca"
      end

      if s.student_time.nil?
        missings_array << "Tiempo de estudio"
      end
 
      if s.gender.blank?
        missings_array << "Sexo"
      end   
      
      if s.date_of_birth.nil?
        missings_array << "Fecha de Nacimiento"
      end

      if  s.city.blank?
        missings_array << "Ciudad de Nacimiento"
      end 

      if s.state_id.nil?
        missings_array << "Estado de Nacimiento"
      end

      if s.country_id.nil?
        missings_array << "País de Nacimiento"
      end

      if s.curp.blank?
        missings_array << "CURP"
      end

      if s.email.blank?
        missings_array << "Email"
      end

      if s.previous_institution.nil?
        missings_array << "Institución Anterior"
      end

      if s.previous_degree_type.blank?
        missings_array << "Tipo de Grado Anterior"
      end

      if s.previous_degree_desc.blank?
        missings_array << "Grado (Grado Anterior)"
      end

      if s.previous_degree_date.nil?
        missings_array << "Fecha de grado Anterior"
      end

      if s.accident_contact.blank?
        missings_array << "Nombre del contacto en caso de accidente"
      end

      if s.accident_phone.blank?
        missings_array << "Telefono del contacto en caso de accidente"
      end

      if s.contact.address1.blank?
        missings_array << "Dirección[Contacto]"
      end

      if s.contact.city.blank?   ## 20
        missings_array << "Ciudad[Contacto]"
      end
      
      if s.contact.state_id.nil?   ## 21
        missings_array << "Estado[Contacto]"
      end

      if s.contact.zip.blank?   ## 22
        missings_array << "Código Postal[Contacto]"
      end

      if s.contact.country_id.nil?   ## 23
        missings_array << "País[Contacto]"
      end
      
      if s.contact.mobile_phone.blank?   ## 24
        missings_array << "Teléfono móvil[Contacto]"
      end

      if s.contact.home_phone.blank?   ## 25
        missings_array << "Teléfono casa[Contacto]"
      end

      if s.contact.work_phone.blank?   ## 26
        missings_array << "Teléfono trabajo[Contacto]"
      end

      if missings_array.size > 0
        total_missings = total_missings + 1
         
        missings_hash[s.id.to_i] = {
              :full_name => s.full_name, 
              :missings=>missings_array, 
              :missings_size=>missings_array.size
              }

        missings_array = []
      end #missings_array.size

    end # total_students.each

    missings_sorted = missings_hash.sort_by{|k,v| v[:missings_size]}.reverse

    file_details = File.new("faltantes_detalle.csv","w")
    file_general = File.new("faltantes_general.csv","w") 
    missings_sorted.each do |key,value|
      #puts "#{key} #{value[:full_name]} #{value[:missings_size]}"
      file_general.puts "#{key},\"#{value[:full_name]}\",#{value[:missings_size]}"
      value[:missings].each do |m|
        file_details.puts "#{key}, \"#{value[:full_name]}\",\"#{m}\""
      end
    end

    file_general.close
    file_details.close
    puts "#{total_missings} de #{masters.size+doctorates.size} registros datos incompletos."
  end #task search
end #namespace
