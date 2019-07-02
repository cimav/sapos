# coding: utf-8
require 'optparse'
namespace :general do
  desc "General Variables and Methods"
  ############################################### GLOBAL VARIABLES #################################################################
  ##################################################################################################################################
  filep     = "#{Rails.root}/log/inscripciones.log"  ## log file route
  @f        = File.open(filep,'a')               
  @env      = Rails.env
  SEND_MAIL         = 2                              ## Posible values: Nobody(0), All(1), Only Admin(2), All&Admin(3) 
  STATUS_CHANGE     = true                           ## False for disable any update
  ADMIN_MAIL        = "enrique.turcott@cimav.edu.mx" ## Administrator Email
  CICLO             = "2018-2"                       ## PREVIOUS TERM
  NCICLO            = "2019-1"                       ## NEW TERM
  
  ############################################## TASK CHECK ########################################################################
  ##################################################################################################################################
  task :check => :environment do
    @yaenciclo= false
    #### Descomentar las 2 lineas siguientes para ver la salida de sql del task
    #Rails.logger.level = Logger::DEBUG
    #ActiveRecord::Base.logger = Logger.new(STDOUT)
    set_line("Iniciando script en check")
    #### NIVELES:
    ## level (1) maestria, (2) doctorado, (3) propedeutico
    ## Primero confirmamos los alumnos de maestria, luego doctorado que requiere otras confirmaciones
    ## Ciclos en estatus de Calificando y con fecha de calificación al dia de la ejecucion del script
    #terms = Term.joins(:program).where("status=3 AND grade_end_date=CURDATE() AND programs.level in (1,2)")
    ## Cualquier ciclo en cualquier estatus en el cual su fecha de final sea hoy 
    #terms = Term.joins(:program).where("end_date=CURDATE() AND programs.level in (1,2)")
    ## Alumnos con materias en el ciclo viejo con estatus en finalizado y/o calificando
    terms = Term.joins(:program).where("programs.level in (1,2) AND terms.name like '%#{CICLO}%' AND status in (3,4)")
    #terms = Term.joins(:program).where("programs.level in (2) AND terms.code = '#{CICLO}' AND terms.status in (3,4)")

    @counter_alumnos = 0
    @counter_no      = 0
    @counter_si      = 0
    if terms.size.eql? 0 then
      set_line("No hay cierres de calificaciones")
    else
      terms.each do |t|
        set_line("<<<<<< - PROGRAMA - >>>>>>")
        set_line("#{t.name} | #{t.program.name}")
        ## Alumnos activos en ese ciclo
        tss = TermStudent.joins(:student).where(:term_id=>t.id,:students=>{:status=>1})
        ## Vamos revisando alumno por alumno (i1)
        tss.each_with_index do |ts,i1|
          counter        = nil
          tcs_grade_sum  = 0
          calificadas    = 0
          reprobadas     = 0
          avances        = 0
          @yaenciclo     = false
          ## Ahora vamos revisando cada materia del alumno
          ## Se deben confirmar las materias calificadas, independientemente si han sido aprobadas o no
          ## Revisando cada materia con estatus 1 o sea activa
          set_line("<<<<< - alumno - >>>>>")
          @counter_alumnos = @counter_alumnos + 1

          snc = TermStudent.joins(:term).where("terms.name like '%#{NCICLO}%' AND student_id=? AND term_students.status in (?)",ts.student.id,[1,2,6])
          if snc.size>0
            set_line("#{ts.student.full_name} ya tiene un registro en el #{NCICLO}")
            @yaenciclo = true
          end

          tcs_grade = nil
          ts.term_course_student.where(:status=>1,:students=>{:status=>1}).each_with_index do |tcs,i2|
             #prom = get_promedio(ts)
             #puts "#{ts.student.full_name}|#{prom[:avg]}|#{prom[:adv_avg]}"
            if @yaenciclo
              break
            end
            tcs_grade = tcs.grade
            level     = ts.student.program.level.to_i
            ## aqui vemos si el alumno es de doctorado y si la materia esta asociada a un avance
            if level.eql? 2 and tcs.term_course.course.notes.eql? "[AI]"
               ## aqui es donde analizamos el avance y lo insertamos en la materia y mandamos un correo al asesor
               set_line("Alumno de doctorado y materia de avance de investigacion [AI]")
               tcs_grade = check_advance(tcs)  
               avances   = avances + 1
            elsif level.eql? 1 and tcs.term_course.course.notes.eql? "[AI]"
               set_line("Alumno de maestria y materia de avance de investigacion [AI]")
               tcs_grade = check_advance(tcs)  
               avances = avances + 1
            end

            if !tcs_grade.nil?
              ## Hay que meterlo al log
              set_line("#{i2} | #{tcs.term_student.student.full_name} | #{tcs.term_course.course.name} | #{tcs.grade}")
              ## Si reprueba una materia hay que checar si es su segunda reprobada
              tcs_grade_sum = tcs_grade_sum + tcs_grade
              if tcs.grade.to_i <= 70
                reprobadas = get_failing(tcs.term_student.student.id)
              end
              calificadas = calificadas + 1
            end ## tcs.grade
            counter = i2
          end  ## ts.term_course_student
          # Si counter es nulo es que el alumno fue inscrito al ciclo pero no a las materias
          # excepto en doctorado que si puede cursarse sin materias
          if get_access(ts,counter,reprobadas,calificadas,avances)
            set_line("Activando inscripción para #{ts.student.full_name}")
            @counter_si      = @counter_si + 1
            ## Le ponemos al alumno el estatus de p_enrollment(pending enrollment)

            if STATUS_CHANGE
              ts.student.status = Student::PENROLLMENT
              ts.student.save
            end
            #set_line("Activando inscripción para #{ts.student.full_name}")
            ## Enviamos correo a su asesor
            #staff   = Staff.find(ts.student.supervisor)
            if ts.student.email_cimav.empty?
              set_line("No se pudo enviar correo a #{ts.student.full_name}")
            else
              prom = get_promedio(ts)
              #puts "#{ts.student.full_name}|#{prom[:avg]}|#{prom[:adv_avg]}
              #content = "{:full_name=>\"#{ts.student.full_name}\",:email=>\"#{ts.student.email}\",:view=>1,:avg=>\"#{prom[:avg]}\",:adv_avg=>\"#{prom[:adv_avg]}\"}"
              #send_mail(staff.email,"Alumno preparado para la inscripcion",content)
              content = "{:ciclo=>\"#{NCICLO}\",:view=>8}"
              #send_mail(ts.student.email_cimav,"Inscripción al ciclo #{NCICLO}",content)
            end ## staff.empty
          else
            set_line("No se activa la inscripción para #{ts.student.full_name}")
            @counter_no = @counter_no + 1
          end ## get_access
        end ## tss
      end  ## terms.each
    end ## if terms.size
    set_line("El numero de alumnos analizados fue #{@counter_alumnos}")
    set_line("No se activaron: #{@counter_no}")
    set_line("Finalizando script")

  end ## task grades


  ##################################################################################################################################
  #####                                              TASK ALARM                                                                #####
  ##################################################################################################################################
  task :alarm => :environment do
    set_line("Iniciando script en alarm")
    ## advances.status = 'P' (PRogramado), term.status=3 (Calificando) y progams.levels 1 y 2 (maestria y doctorado) 
   advances = Advance.joins(:student=>[:term_students=>:term]).joins(:student=>:program).where("advances.status in (?) AND terms.status in (?) AND programs.level in (?) AND advances.advance_date between terms.start_date and terms.end_date AND advances.advance_type in (?) AND advances.title !=''",['P'],[3],[1,2],[1]).select("advances.*,terms.id as terms_id")

## advances = Advance.joins(:student=>[:term_students=>:term]).joins(:student=>:program).where("advances.status in (?) AND terms.status in (?) AND programs.level in (?) AND advances.advance_date between terms.start_date and terms.end_date AND advances.advance_type in (?) AND advances.student_id in (?)",['P'],[3],[1,2],[1],[1168,1739,1667,1616,1617,1647,1615,1614,1613,1619,1618,1646,1645]).select("advances.*,terms.id as terms_id")

##     advances = Advance.joins(:student=>[:term_students=>:term]).joins(:student=>:program).where("advances.status in (?) AND terms.status in (?) AND programs.level in (?) AND advances.advance_date between terms.start_date and terms.end_date AND advances.advance_type in (?) AND advances.student_id in (?)",['P'],[3],[1,2],[1],[1734]).select("advances.*,terms.id as terms_id")
    
   ## advances = Advance.joins(:student=>[:term_students=>:term]).joins(:student=>:program).where("advances.status in (?) AND terms.status in (?) AND programs.level in (?) AND advances.advance_date between terms.start_date and terms.end_date and students.id=1714",['P'],[1,2,3],[1,2]).select("advances.*,terms.id as terms_id")
    ## advances = Advance.joins(:student=>[:term_students=>:term]).joins(:student=>:program).where("advances.status in (?) AND terms.status in (?) AND programs.level in (?) AND advances.advance_date between terms.start_date and terms.end_date and students.id=?",['P'],[3],[1,2],1486).select("advances.*,terms.id as terms_id")

=begin
    advances.each do |a|
     puts "#{a.id} #{a.student_id} #{a.status} #{a.title}"
    end
=end

=begin
  HELPER
=end
    counter = 1
    if advances.size.eql? 0
      set_line("No hay fechas de avances abiertas")
    else
      advances.each do |a|
        #puts "#{counter} #{a.student.full_name}"
        t1 = Staff.find(a.tutor1) rescue nil
        t2 = Staff.find(a.tutor2) rescue nil
        t3 = Staff.find(a.tutor3) rescue nil
        t4 = Staff.find(a.tutor4) rescue nil
        t5 = Staff.find(a.tutor5) rescue nil
        # avisarle a los asesores que deben calificar y a los externos la clave y el link de acceso
  
        t_array = [t1,t2,t3,t4,t5]

=begin
        t_array.each do |t|
          if !t.nil?
            if t.institution_id.eql? 1
              puts "CIMAV: #{t.id} #{t.full_name}"
            else
              puts "EXTER: #{t.id} #{t.full_name}"
            end
          end
=end

=begin
  HELPER
=end
        t_array.each do |t|
          if !t.nil?
            ## puts t.full_name rescue "N.D"
            ## DEV
            #if t.id.eql? 511
              if t.institution_id.eql? 1
                content = "{:advance=>\"#{a.id}\",:view=>3,:staff=>\"#{t.id}\"}"
              else
                token = Token.new
                token.attachable_id     = t.id
                token.attachable_type   = t.class.to_s
                token.token             = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
                token.status            = 1
                token.expires           = Term.find(a.terms_id).grade_end_date
                token.save
                content = "{:advance=>\"#{a.id}\",:staff=>\"#{t.id}\",:token=>\"#{token.token}\",:view=>4}"
              end  ## end id-else
              ## PROD
              send_mail(t.email,"Alerta Calificaciones",content)
              ##send_mail("enrique.turcott@cimav.edu.mx","Alerta Calificaciones",content)
            #end  ## if t.id.eql
          end ## end nil?
########################################### aqui va el =end
        end ## end t_array.each
        counter = counter + 1
      end #end each
    end #end if-else
    # buscar asesores con alumnos en fechas

  end ## task alarm

  ##################################################################################################################################
  #####                                              TASK EXTERNALS                                                            #####
  ##################################################################################################################################
  task :externals_alarm => :environment do 
    set_line("Iniciando script en externals alarm")
  access      = "default"
  only_check  = false

  ARGV.each { |a| task a.to_sym do ; end }

  ARGV.each_with_index do |a,index|
    if index>0
      if a.eql? "check"
        access = "check"
        only_check  = true
      elsif a.eql? ""
        access = "default"
      else
        puts "Opción desconocida"
        exit
      end
    end#if index>0
  end

  advances_status = ['P']  
  advance_type    = [1] 
  terms_status    = [3]
  programs_level  = [1,2]
    
  advances = Advance.select("advances.*,terms.id as terms_id").joins(:student=>[:term_students=>:term]).joins(:student=>:program).where(:status=>advances_status,:advance_type=>advance_type).where("terms.status in (?) AND programs.level in (?) AND advances.advance_date between terms.start_date and terms.end_date",terms_status,programs_level)
  puts advances.size
  #advances = Advance.joins(:student=>[:term_students=>:term]).joins(:student=>:program).where("advances.status in (?) AND terms.status in (?) AND programs.level in (?) AND advances.advance_date between terms.start_date and terms.end_date AND advances.advance_type in (?) AND advances.title !=''",['P'],[3],[1,2],[1]).select("advances.*,terms.id as terms_id")
  advances.each do |a|
    t1 = Staff.find(a.tutor1) rescue nil
    t2 = Staff.find(a.tutor2) rescue nil
    t3 = Staff.find(a.tutor3) rescue nil
    t4 = Staff.find(a.tutor4) rescue nil
    t5 = Staff.find(a.tutor5) rescue nil

    t_array = [t1,t2,t3,t4,t5]
    
    t_array.each do |t|
      unless t.nil?
        unless t.institution_id.eql? 1
          puts "#{a.id} #{t.full_name}"
          unless only_check
            token = Token.new
            token.attachable_id     = t.id
            token.attachable_type   = t.class.to_s
            token.token             = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
            token.status            = 1
            token.expires           = Term.find(a.terms_id).grade_end_date
            token.save
            content = "{:advance=>\"#{a.id}\",:staff=>\"#{t.id}\",:token=>\"#{token.token}\",:view=>4}"
            send_mail(t.email,"Alerta Calificaciones",content)
          end
        end
      end
    end
  end

  end ## task externals_alarm
end ## namespace

  ####################################################### METODOS ##############################################################
  ## Obtiene promedio del ciclo actual vato loco ese
  def get_promedio(ts)
    courses_number = ts.term_course_student.size
    counter   = 0
    tcs_sum   = 0
    avg       = 0
    ai        = 0
    ev        = 0
    adv_grade = nil

    ts.term_course_student.where(:status=>1).each do |tcs|
      #puts "#{tcs.term_course.course.name} #{tcs.grade} #{tcs.grade.nil?}"
      #puts "#{tcs.term_student.student.full_name}"
      #puts "#{tcs.id}"
      if tcs.term_course.course.notes.eql? "[AI]"
        ai = ai + 1
      end

      if !tcs.grade.nil?
        tcs_sum = tcs_sum + tcs.grade 
        counter = counter + 1
      end
    end

    ## si no hay materia relacionada buscamos la evaluacion
    if ai.eql? 0
      s        = ts.student
      term     = ts.term
      # buscamos el avance para este ciclo
      advances = s.advance.where("advances.advance_date between ? and ?",term.start_date,term.end_date)
      if !advances.size.eql? 0
        a = advances[0]
        t_g = get_tutors_and_grades(a,term)
        tutors = t_g[0]
        grades = t_g[1]
        sum    = t_g[2]
        quorum = t_g[3]
        if !grades.eql? 0
          adv_grade   = sum / grades
        end
      end
    end

    if !counter.eql? 0
      avg = tcs_sum/counter
    end

    #puts "El alumno #{ts.student.full_name} tiene un promedio de #{avg} con #{counter} materias calificadas lo que incluye #{ev} evaluacion"
    return {:avg=>avg,:adv_avg=>adv_grade}
  end
  ## Inserta una linea en el log
  def set_line(text)
    @f.write "[#{Time.now.to_s}] "
    @f.puts text
  end

  ## Obtener reprobadas
  def get_failing(s_id)
    return TermCourseStudent.joins(:term_student).where(:term_students=>{:student_id=>s_id},:status=>1).where("grade<=?",70).size
  end

  ## pone un mail en la pila
  def send_mail(to,subject,content)
    set_line("Entrando a send_mail")
    if [1,2,3].include? SEND_MAIL
      if to.nil?
        set_line("Error, email vacio. #{content}")
      else
        if SEND_MAIL.eql? 2
          to = ADMIN_MAIL
        end
        mail    = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>to,:subject=>subject,:content=>content,:status=>0})
        mail.save
        set_line("Enviando correo a #{to}")
        
        if SEND_MAIL.eql? 3
          mail    = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>ADMIN_MAIL,:subject=>subject,:content=>content,:status=>0})
          mail.save
          set_line("Enviando correo a #{to}")
        end
      end
    else
        set_line("Enviando correo a #{to} [DESACTIVADO]")
    end ## SEND_MAIL
  end

  ## revisa si ya se califico el avance de investigación de doctorada asociado a una materia
  def check_advance(tcs)
    if tcs.grade.nil?
      s        = tcs.term_student.student
      term     = tcs.term_student.term
      # buscamos el avance para este ciclo
      advances = s.advance.where("advances.advance_date between ? and ?",term.start_date,term.end_date)
      if advances.size.eql? 0
        set_line("No hay avances de investigacion registrados para #{s.full_name} #{tcs.term_course.course.name}")
        return nil
      else ## else advances.size.eql
        a      = advances[0]
        set_line("Procedemos a analizar el avance de investigacion ")

        t_g = get_tutors_and_grades(a,term)
        tutors = t_g[0]
        grades = t_g[1]
        sum    = t_g[2]
        quorum = t_g[3]

        if grades>0
          if quorum
            prom   = sum / grades
            set_line("Se han calificado #{grades} grados de #{tutors} tutores. El promedio es #{prom}.")
            if STATUS_CHANGE
              tcs.grade = prom
              tcs.save
              # Cambiamos el estatus del avance a Concluido
              a.status = 'C'
              a.save
              return tcs.grade
            else
              return prom
            end

          else
            set_line("Se han calificado #{grades} grados de #{tutors} tutores. No hay quorum.")
          end  ## if quorum
        else
          set_line("Ninguno de los #{tutors} tutores ha calificado.")
        end  ## if grades
      end #else advances.size.eql

      return nil
    else  ## else grade.nil?
      set_line("El avance para esa materia ya ha sido revisado devolvemos la calificacion almacenada")
      return tcs.grade
    end  ## grade.nil?
  end
  
  ## revisa si ya se califico el avance de investigación de doctorada asociado a un ciclo, recibe t = term, s= student
  def check_advance_term(t,s)
    advances = s.advance.where("advances.advance_date between ? and ? and advances.status in (?)",t.start_date,t.end_date,['P','C'])
    if advances.size.eql? 0
      set_line("No hay avances de investigacion registrados para #{s.full_name} para el ciclo #{t.name}")
      return false
    else
      a      = advances[0]
      set_line("Procedemos a analizar el avance de investigacion sin materias de #{s.full_name} ... ")
      t_g = get_tutors_and_grades(a,t)
      tutors = t_g[0]
      grades = t_g[1]
      sum    = t_g[2]
      quorum = t_g[3]
      if grades>0
        if quorum
          prom   = sum / grades
          set_line("Se han calificado #{grades} grados de #{tutors} tutores. El promedio es #{prom}.")
          # Cambiamos el estatus del avance a Concluido
          a.status = 'C'
          a.save
          if prom.to_i <= 70
            set_line("Se ha reprobado el avance de investigacion")
            return false
          else
            return true
          end
        else
          set_line("Se han calificado #{grades} grados de #{tutors} tutores. No hay quorum.")
          return false
        end  ## if quorum
      else ## else grades
        set_line("Ninguno de los #{tutors} tutores ha calificado.")
        return false
      end  ## if grades
    end #else advances.size.eql
  end
  
  ## Para obtener los datos de un avance de investigacion
  ## a = advance, t= term
  def get_tutors_and_grades(a,t)
    tutors = 0
    grades = 0
    sum    = 0
    quorum = false
    text   = ""

    if !a.tutor1.nil?
      text = "Tutor 1 "
      tutors = tutors + 1
      if !a.grade1.nil?
         sum = sum + a.grade1
         grades = grades + 1
         text += "ha calificado #{a.grade1} "
      else
         text += "no ha calificado "
      end
      set_line(text)
    end

    if !a.tutor2.nil?
      text = "Tutor 2 "
      tutors = tutors + 1
      if !a.grade2.nil?
         sum = sum + a.grade2
         grades = grades + 1
         text += "ha calificado #{a.grade2} "
      else
         text += "no ha calificado"
      end
      set_line(text)
    end
    
    if !a.tutor3.nil?
      text = "Tutor 3 "
      tutors = tutors + 1
      if !a.grade3.nil?
         sum = sum + a.grade3
         grades = grades + 1
         text += "ha calificado #{a.grade3} "
      else
         text += "no ha calificado "
      end
      set_line(text)
    end
    
    if !a.tutor4.nil?
      text = "Tutor 4 "
      tutors = tutors + 1
      if !a.grade4.nil?
         sum = sum + a.grade4
         grades = grades + 1
         text += "ha calificado #{a.grade4} "
      else
         text += "no ha calificado "
      end
      set_line(text)
    end
    
    if !a.tutor5.nil?
     text = "Tutor 5 "
      tutors = tutors + 1
      if !a.grade5.nil?
         sum = sum + a.grade5
         grades = grades + 1
         text += "ha calificado #{a.grade5} "
      else
         text += "no ha calificado "
      end
      set_line(text)
    end
          
    if grades.eql? 1 and tutors.eql? 1
      quorum = true
    elsif grades.eql? 2 and tutors.eql? 2
      quorum = true
    elsif grades>=2 and tutors.eql? 3
      quorum = true
    elsif grades>=2 and tutors>=4
      quorum = true
    elsif grades>=3 and tutors.eql? 5
      quorum = true
    end
    
    #a.student.term_students.find{|a| a.term.name.match("#{CICLO}")
    today = Date.today
    range = t.start_date
    range = t.grade_start_date..t.grade_end_date
    ## si estamos en fechas de calificaciones nos brincamos la evaluacion a menos que ya hayan calificado todos los tutores
 #   if !grades.eql? tutors
 #     if range===today
 #       set_line("Todavia estamos en calificaciones de evaluaciones no se hace el analisis")
 #       return [tutors,grades,0,false]
 #     end
#    end

    return [tutors,grades,sum,quorum]
  end

  ## Define acceso a la activación de la inscripción para el alumno
  def get_access(ts,counter,reprobadas,calificadas,avances)
    s    = ts.student
    term =   ts.term
    ## si el numero de reprobadas es menor a 2 accesamos
    if reprobadas < 2
      if s.program.level.to_i.eql? 2 ############################## Alumnos de doctorado
        if counter.nil? ## sin materias
          ## si ya esta inscrito al ciclo no le damos acceso
          if @yaenciclo
            return false
          end

          set_line("El alumno #{s.full_name} es de doctorado y no registra materias por lo que nos disponemos a analizar sus evaluaciones para el ciclo #{term.name}")
          return check_advance_term(term,s)
        
        else  ## con materias
          pasa    = true
          counter = counter + 1   
          if avances.eql? 0 and counter>0 ## Si no tiene avances hay que ver si los tiene
            if check_advance_term(term,s)
               set_line("El alumno ha aprobado el avance sin materia relacionada") 
            else
              set_line("El alumno no ha pasado el avance sin materia relacionada")
              pasa = false
            end
          end
          
          if pasa
            set_line("El alumno #{s.full_name} esta inscrito a #{counter} materias de las cuales se han calificado #{calificadas}")
          else
            set_line("El alumno #{s.full_name} esta inscrito a #{counter} materias de las cuales se han calificado #{calificadas} pero no ha pasado el avance")
            return false
          end

          if counter.eql? calificadas
            return true
          else
            return false
          end
        end ##if counter.nil
      else ############################################## Alumnos de maestria
        if @yaenciclo
          return false
        end

        if counter.nil? ## sin materias
          set_line("El alumno #{s.full_name} no curso ninguna materia pero aun asi fue inscrito al ciclo")
          return false
        else  ## con materias
          counter = counter + 1
          set_line("El alumno #{s.full_name} esta inscrito a #{counter} materias de las cuales se han calificado #{calificadas}")
          if counter.eql? calificadas
            return true
          else
            return false
          end
        end ## if counter.nil?
      end # if level.eql? 2
    else ## Si las reprobadas son 2 o mas avisamos de la baja
      staff = Staff.find(890)
      puts "BAJA: #{s.full_name}"
      #staff   = Staff.find(s.supervisor) 

      set_line("El alumno #{s.full_name} sera dado de baja del programa #{s.program.name}")
      ## Enviar correo asesor y a Sandra y al mismo alumno
      content = "{:full_name=>\"#{s.full_name}\",:email=>\"#{s.email}\",:view=>2}"
      send_mail(staff.email,"Baja de alumno",content)
      #send_mail("sandra.beltran@cimav.edu.mx","Baja de alumno",content)
      send_mail("atencion.posgrado@cimav.edu.mx","Baja de alumno",content)
      send_mail(s.email,"Baja de alumno",content)
      send_mail(s.email_cimav,"Baja de alumno",content)
      return false
    end #if reprobadas
  end  ## get_access
__END__
