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
      Nombre|Apellido
      Nombre|Apellido
         ...  |  ...
         etc  |  etc

  El objetivo es obtener los ids para poner los student_id en nulo porque no los dejan pasar de propedeutico a maestria
=end
    archivo = "/home/enrique/sapos/lib/tasks/master_applicants_file"
    counter = 0
    counter_b = 0
    ids = Array.new
    File.open(archivo,'r') do |s|
      while line = s.gets
        #puts line
        full_name = line.split("|")
        first_name = full_name[0].chomp
        last_name  = full_name[1].chomp

        first_name = first_name.gsub(/^\s+/,"")
        first_name = first_name.gsub(/\s+$/,"")

        last_name = last_name.gsub(/^\s+/,"")
        last_name = last_name.gsub(/\s+$/,"")
        
        puts "Linea #{counter+1}: #{first_name.chomp}|#{last_name.chomp}"

=begin
        student =  Student.where("concat(TRIM(last_name),' ',TRIM(last_name2)) LIKE :a AND first_name LIKE :b",  {:a => "%#{last_name}%", :b => "%#{first_name}%"}).order(:id).last

        if !student.nil?
          program = Program.find(student.program_id).prefix rescue "N.D."
          puts "Busqueda Estudiantes #{counter}: #{student.full_name} [#{student.id},#{program},\"#{student.status}\"]"
          counter_b = counter_b + 1 
        end
=end

        app =  Applicant.where("concat(TRIM(primary_last_name),' ',TRIM(second_last_name)) LIKE :a AND first_name LIKE :b",  {:a => "%#{last_name}%", :b => "%#{first_name}%"}).order(:id).last
        
        if !app.nil?
          puts "Busqueda #{counter}: #{app.full_name} [#{app.id}][#{app.program_id},\"#{Applicant::STATUS[app.status]}\"]" 
          counter_b = counter_b + 1 
          ids<< app.id
        end

      
        counter = counter + 1
      end # while line
    end #File
    
    puts "Lineas totales: #{counter}"
    puts "Matches: #{counter_b}"
    puts "Ids: #{ids}"
  end## end task get_applicants_id

  ############################################################################################################################
  #  get_reprobated: obtiene alos alumnos que tengan mas de una materia reprobada de todos los tiempos en orden descendente
  ############################################################################################################################
  task :get_reprobated => :environment do 
     #reprobated = TermCourseStudent.select("distinct students.id as id, count(*) as counter").joins(:term_student=>:student).where("grade < 70 AND students.status in (?)",[1,6]).group("students.id").order("counter desc").having("counter > 1").map {|i| [i.id,i.counter] }
     reprobated = TermCourseStudent.select("distinct students.id as id, count(*) as counter").joins(:term_student=>:student).where("grade < 70 AND students.status in (?)",[1,6]).group("students.id").order("counter desc").map {|i| [i.id,i.counter] }

     reprobated.each do |r|
       s = Student.find(r[0])
       puts "#{r[1]} #{s.full_name} [#{s.id}] #{Student::STATUS[s.status]}"
     end

     puts "Total: #{reprobated.size}"
  end #task get_reprobated

  ############################################################################################################################
  #  get_advances_files: Busca por matricula los alumnos especificados en el archivo y manda al destino remoto el ultimo archivo
  #   registrado como avance de investigacion
  ############################################################################################################################
  task :get_advances_files => :environment do 
    archivo= "/home/rails/sapos/tmp/students_codes"
    counter = 1
    host    = "10.0.5.107"
    user    = ""
    password = ""
   Net::SCP.start(host,user,:password=>password) do |scp|
    File.open(archivo,'r') do |s|
        while line = s.gets
          if (counter%2)==1
            student = Student.where(:card=>line.chomp)
            if student.size==0
              salida = "No existe ese estudiante"
            elsif student.size==1
              student = student[0] 
              salida  = "#{student.id} #{student.full_name}"
            
              safs = StudentAdvancesFile.joins(:term_student).where(:term_students=>{:student_id=>student.id}).order("student_advances_files.created_at desc").first
     
              saf_splitted = safs.file.to_s.split("/")
              file_name    = saf_splitted[saf_splitted.size-1]
              ext_splitted = file_name.split(".")
              extension    = ext_splitted[ext_splitted.size-1]
              
              new_file_name= "#{student.first_name.lstrip.rstrip} #{student.last_name.lstrip.rstrip} #{student.last_name2.lstrip.rstrip}.#{extension}"
           
              new_file_name = "#{I18n.transliterate(new_file_name.gsub("\s","_"))}"
              scp.upload!(safs.file.to_s,"/home/enrique/Avances/#{new_file_name}")
  
            else
              salida = "Existe mas de un registro"
            end
            puts "|#{line.chomp}|#{salida}"
          end # if %
          counter = counter + 1
        end # while
    end # File
    end # Net::SCP

  end #task get_advances_files

  ############################################################################################################################
  #  search_end_date_null : Busca los alumnos que tienen el campo end_date en nulo
  ############################################################################################################################
  task :search_end_date_null => :environment do 
    students = Student.where(:status=>[2,5]).where("end_date is NULL")
    students.each do |s|
      p "#{s.full_name} #{s.status} #{s.start_date}"
    end
    p "#{students.size}"
  end #task search_end_date_null
  
  ############################################################################################################################
  # fill_end_date : rellena los campos en null con la fecha de tesis si es que existe
  ############################################################################################################################
  task :fill_end_date => :environment do 
    students = Student.where(:status=>[2,5]).where("end_date is NULL")
    counter = 0
    students.each do |s|
      if !s.thesis.defence_date.nil?
        
        p "#{s.id} #{s.full_name} #{s.thesis.defence_date}"
        s.end_date = s.thesis.defence_date
        s.save
        counter = counter + 1
      end
    end
    p "#{counter} registros cambiados"
  end #task fill_end_date

  ############################################################################################################################
  # search_and_purify_students: busca los espacios en blanco sobrantes de los registros y los purifica de tabla estudiantes
  ############################################################################################################################
  task :search_and_purify_students => :environment do
    students  = Student.all
    counter = 0
    
    students.each do |s|
      puts "##### ID: #{s.id}"
      full_name = String.new
  
      first_name = purifier(s.first_name) if !s.first_name.blank?
      last_name  = purifier(s.last_name) if !s.last_name.blank?
      last_name2 = purifier(s.last_name2) if !s.last_name2.blank?

      s.first_name = first_name if !first_name.nil?
      s.last_name = last_name if !last_name.nil?
      s.last_name2 = last_name2 if !last_name2.nil?


      full_name = "#{first_name.to_s.gsub(" ","")}#{last_name.to_s.gsub(" ","")}#{last_name2.to_s.gsub(" ","")}"

      if full_name.size>0
        puts "|#{first_name}|#{last_name}|#{last_name2}|"
        counter = counter + 1
      
        if s.save(validate: false)
          puts "Save!!"
        else
          puts "Errors: #{s.errors.full_messages}"
        end
      end
    end # students.each
    puts "Estudiantes: #{students.size} Blancos: #{counter}"
  end ## task search_and_purify

  ##################################################################################################################################
  # search_and_purify_internships: busca los espacios en blanco sobrantes de los registros y los purifica de tabla servicios CIMAV
  ##################################################################################################################################
  task :search_and_purify_internships => :environment do
    internships  = Internship.all
    counter = 0
    internships.each do |i|
      puts "##### ID: #{i.id}"
      full_name = String.new
 
      first_name = purifier(i.first_name) if !i.first_name.blank?
      last_name  = purifier(i.last_name) if !i.last_name.blank?
   
      i.first_name = first_name if !first_name.nil?
      i.last_name = last_name if !last_name.nil?

      full_name = "#{first_name.to_s.gsub(" ","")}#{last_name.to_s.gsub(" ","")}"

      if full_name.size>0
        puts "|#{first_name}|#{last_name}"
        counter = counter + 1

        if i.save(validate: false)
          puts "Save!!"
        else
          puts "Errors: #{i.errors.full_messages}"
        end
      end
    end #internships.each
    puts "Servicios: #{internships.size} Blancos: #{counter}"
  end ## task search_and_purify_internships

  ##################################################################################################################################
  # search_and_finalize_internships: finaliza los servicios que por alguna razón se quedaron abiertos
  ##################################################################################################################################
  task :search_and_finalize_internships => :environment do
    internships = Internship.where(:status=>0)
    c_num   = 0
    c_date  = 0
    c_nulls = 0 

    internships.each do |i|
      date = Date.today
      if i.end_date.nil? 
        c_nulls = c_nulls + 1
        
        # si fueron creados hace mas de 6 meses pasan a inactivos
        if i.created_at < Date.today-188
          puts "#############"
          puts i.full_name
          puts "Start Date: #{i.start_date}"
          puts "Created at: #{i.created_at}"
          i.status = 2 #inactivo
          unless i.save(validate: false)
            puts "#{i.id} Error! #{i.errors.full_messages}"
          end
        end
      else
        if i.end_date < Date.today-188
          c_date   = c_date + 1

          i.status= 1  #finalizado
          unless i.save(validate: false)
            puts "#{i.id} Error! #{i.errors.full_messages}"
          end
        end
      end

    end
    puts "Servicios: #{internships.size} Con fecha final de 6 meses: #{c_date}  Nulls: #{c_nulls}"
  end ## task search_and_finalize_internships
  
  ##################################################################################################################################
  # search_and_finalize_internships: finaliza los servicios que por alguna razón se quedaron abiertos
  ##################################################################################################################################
  task :search_and_finalize_if_certificate => :environment do
    c_num = 0
    internships = Internship.where(:status=>0)
    internships.each do |i|
      unless i.end_date.nil?
        certificates = Certificate.where(:attachable_type=>i.class.to_s,:attachable_id=>i.id,:type_id=>9)
        certificates.each do |c|
          c_num = c_num + 1
          puts "Certificado: #{c.created_at}"
          break
        end
      end
    end

    puts "Servicios: #{internships.size} Con certificado: #{c_num}"
  end ## task search_and_finalize_if_certificate

  ##################################################################################################################################
  # send_applicants_email
  ##################################################################################################################################
  task :send_applicants_email => :environment do
    applicants = Applicant.where(:id=>[1248,1249,1250,1251,1252,1253,1254,1255,1256])
    applicants.each do |a|
      puts "#{a.full_name} #{a.email}"
      content = "{:applicant_id=>\"#{a.id}\",:view=>29}"
      send_email(a.email,"Solicitud nuevo ingreso CIMAV",content,a)
      #content = "{:applicant_id=>\"#{a.id}\",:view=>30}"
      #send_email(Settings.school_services1,"Un aspirante ha solicitado password",content,a)
    end
  end ## task send_applicants_email
 
  ##################################################################################################################################
  # Show libs
  ##################################################################################################################################
  task :show_libs => :environment do
    Dir["lib/toads/**/*.rb"].each do |path|
      puts  path
    end # Dir
  end  ## task show_libs

  ##################################################################################################################################
  # Unsubscribe: elimina materias y deja al alumno como si nunca se hubiera inscrito, para pruebas
  ##################################################################################################################################
  task :unsubscribe => :environment do 
    s_id = 2201
    term = '2019-2 Chihuahua' 
    s = Student.find(s_id)
    term_student = nil 

    puts s.full_name
    s.term_students.each do |ts| 
      if ts.term.name.eql? term
        term_student = ts
        ts.term_course_student.each do |tcs|
          puts tcs.destroy
        end
      end
    end
    
    puts term_student.destroy

    s.status = 6
    puts s.save(:validation=>false)
  end ## task unsubscribe

end ## namespace

################################################################### METODOS #################################################
def purifier(string)
  flag = false
  
  if string.match(/^\s+.*/)
    flag = true
  end

  if string.match(/.*\s+$/)
    flag = true
  end

  if string.match(/\s\s+/)
    flag = true
  end

  if flag
    string          = string.strip
    string_array    = string.split(" ")
    string_purified = string_array.join(" ")
    return string_purified
  else
    return nil
  end
end ## def purifier

def send_email(to,subject,content,object)
  mail    = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>to,:subject=>subject,:content=>content,:status=>0})

  if mail.save
    mail.status= 0;
    mail.save
  else
    ActivityLog.new({:user_id=>object.id,:activity=>"{:user_object=>'#{object.class}',:activity=>'Error al guardar email <#{to}>'}"}).save
  end
end

