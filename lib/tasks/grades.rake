# coding: utf-8
namespace :grades do
  desc "Grades Close at end of term"
  ##################################################################################################################################
  #####                                           TASK CHECK                                                                   #####
  ##################################################################################################################################
  task :check => :environment do
    ################################################################################################################################
    ###########################################        NOTAS        ################################################################
    #  CONFIGURACION
    #  SEND_MAIL possible values: Nobody(0), All (1) , Only_Admin(2), All&Admin(3)
    #  STATUS_CHANGE possible values: false, true
    #
    # Los valores default para produccion deberian ser:
    #  SEND_MAIL = 1 
    #  STATUS_CHANGE = true
    ################################################################################################################################
    ################################################################################################################################
    filep     = "#{Rails.root}/log/inscripciones.log"
    @f        = File.open(filep,'a')
    @env      = Rails.env
    SEND_MAIL         = 0
    STATUS_CHANGE     = false
    ADMIN_MAIL        = ""
    #### Descomentar las 2 lineas siguientes para ver la salida de sql del task
    #Rails.logger.level = Logger::DEBUG
    #ActiveRecord::Base.logger = Logger.new(STDOUT)
    set_line("Iniciando script en check")
    #### NIVELES:
    # level (1) maestria, (2) doctorado, (3) propedeutico
    # Primero confirmamos los alumnos de maestria, luego doctorado que requiere otras confirmaciones
    # Ciclos en estatus de Calificando y con fecha de calificación al dia de la ejecucion del script
    #terms = Term.joins(:program).where("status=3 AND grade_end_date=CURDATE() AND programs.level in (1,2)")
    # Cualquier ciclo en cualquier estatus en el cual su fecha de final sea hoy 
    terms = Term.joins(:program).where("end_date=CURDATE() AND programs.level in (1,2)")

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
          counter     = nil
          calificadas = 0
          reprobadas  = 0
          ## Ahora vamos revisando cada materia del alumno
          ## Se deben confirmar las materias calificadas, independientemente si han sido aprobadas o no
          ## Revisando cada materia con estatus 1 o sea activa
          set_line("<<<<< - alumno - >>>>>")
          ts.term_course_student.where(:status=>1,:students=>{:status=>1}).each_with_index do |tcs,i2|
            tcs_grade = tcs.grade
            if ts.student.program.level.to_i.eql? 2 and tcs.term_course.course.notes.eql? "[AI]"
               ## aqui es donde analizamos el avance y lo insertamos en la materia y mandamos un correo al asesor
               set_line("Alumno de doctorado y materia de avance de investigacion [AI]")
               tcs_grade = doc_advance(tcs)  
            end

            if !tcs_grade.nil?
              ## Hay que meterlo al log
              set_line("#{i2} | #{tcs.term_student.student.full_name} | #{tcs.term_course.course.name} | #{tcs.grade}")
              ## Si reprueba una materia hay que checar si es su segunda reprobada
              if tcs.grade.to_i <= 70
                reprobadas = get_failing(tcs.term_student.student.id)
              end

              calificadas = calificadas + 1
            end ## tcs.grade
            counter = i2
          end  ## ts.term_course_student

          # Si counter es nulo es que el alumno fue inscrito al ciclo pero no a las materias
          # excepto en doctorado que si puede cursarse sin materias
          if get_access(ts,counter,reprobadas,calificadas)
            set_line("Activando inscripción para #{ts.student.full_name}")
            ## Le ponemos al alumno el estatus de p_enrollment(pending enrollment)
            if STATUS_CHANGE
              ts.student.status = Student::PENROLLMENT
              ts.student.save
            end
            ## Enviamos correo a su asesor
            staff   = Staff.find(ts.student.supervisor)
            if staff.email.empty?
              set_line("No se pudo enviar correo a #{staff.full_name}")
            else
              content = "{:full_name=>\"#{ts.student.full_name}\",:email=>\"#{ts.student.email}\",:view=>1}"
              send_mail(staff.email,"Alumno preparado para la inscripcion",content)
            end ## staff.empty
          else
            set_line("No se activa la inscripción para #{ts.student.full_name}")
          end ## get_access
        end ## tss
      end  ## terms.each
    end ## if terms.size

    set_line("Finalizando script")
    
  end ## task grades


  ##################################################################################################################################
  #####                                              TASK ALARM                                                                #####
  ##################################################################################################################################
  task :alarm => :environment do
    set_line("Iniciando script en alarm")
    ## comprobar si falta una semana para calificaciones
    #advances = Advance.joins(:student=>[:term_students=>:term]).joins(:student=>:program).where("terms.status in (?) AND terms.grade_start_date<=date_sub(curdate(), INTERVAL 15 DAY) AND programs.level in (?)",[3],[1,2]).select("advances.*,terms.id as terms_id")
    advances = Advance.joins(:student=>[:term_students=>:term]).joins(:student=>:program).where("terms.status in (?) AND terms.grade_start_date=curdate() AND programs.level in (?)",[3],[1,2]).select("advances.*,terms.id as terms_id")
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
  
        t_array.each do |t|
          if !t.nil?
            ## puts t.full_name rescue "N.D"
            ## DEV
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
            end
            ## PROD
            send_mail(t.email,"Alerta Calificaciones",content)
          end
        end
  
        counter = counter + 1
      end #end each
    end #end if-else
    # buscar asesores con alumnos en fechas


  end ## task alarm

end ## namespace

  ####################################################### METODOS ##############################################################
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
  def doc_advance(tcs)
    if tcs.grade.nil?
      s        = tcs.term_student.student
      term     = tcs.term_student.term
      ## Aparte DEbería estar en estatus de concluida
      advances = s.advance.where("advances.advance_date between ? and ?",term.start_date,term.end_date)
      if advances.size.eql? 0
        set_line("No hay avances de investigacion registrados para #{s.full_name} #{tcs.term_course.course.name}")
        return nil
      else ## else advances.size.eql
        a      = advances[0]
        set_line("Procedemos a analizar el avance de investigacion de #{s.full_name} ... ")

        t_g = get_tutors_and_grades(a)
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
  def doc_advance_term(t,s)
    advances = s.advance.where("advances.advance_date between ? and ?",t.start_date,t.end_date)
    if advances.size.eql? 0
      set_line("No hay avances de investigacion registrados para #{s.full_name} para el ciclo #{t.name}")
      return false
    else
      a      = advances[0]
      set_line("Procedemos a analizar el avance de investigacion sin materias de #{s.full_name} ... ")
      t_g = get_tutors_and_grades(a)
      tutors = t_g[0]
      grades = t_g[1]
      sum    = t_g[2]
      quorum = t_g[3]
      if grades>0
        if quorum
          prom   = sum / grades
          set_line("Se han calificado #{grades} grados de #{tutors} tutores. El promedio es #{prom}.")
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
  def get_tutors_and_grades(a)
    tutors = 0
    grades = 0
    sum    = 0
    quorum = false
    if !a.tutor1.nil?
      set_line("Tutor 1 activo")
      tutors = tutors + 1
      if !a.grade1.nil?
         sum = sum + a.grade1
         grades = grades + 1
         set_line("Tutor 1 ha calificado #{a.grade1}")
      else
         set_line("Tutor 1 no ha calificado")
      end
    end
    
    if !a.tutor2.nil?
      set_line("Tutor 2 activo")
      tutors = tutors + 1
      if !a.grade2.nil?
         sum = sum + a.grade2
         grades = grades + 1
         set_line("Tutor 2 ha calificado #{a.grade2}")
      else
         set_line("Tutor 2 no ha calificado")
      end
    end
    
    if !a.tutor3.nil?
      set_line("Tutor 3 activo")
      tutors = tutors + 1
      if !a.grade3.nil?
         sum = sum + a.grade3
         grades = grades + 1
         set_line("Tutor 3 ha calificado #{a.grade3}")
      else
         set_line("Tutor 3 no ha calificado")
      end
    end
    
    if !a.tutor4.nil?
      set_line("Tutor 4 activo")
      tutors = tutors + 1
      if !a.grade4.nil?
         sum = sum + a.grade4
         grades = grades + 1
         set_line("Tutor 4 ha calificado #{a.grade4}")
      else
         set_line("Tutor 4 no ha calificado")
      end
    end
    
    if !a.tutor5.nil?
      set_line("Tutor 5 activo")
      tutors = tutors + 1
      if !a.grade5.nil?
         sum = sum + a.grade5
         grades = grades + 1
         set_line("Tutor 5 ha calificado #{a.grade5}")
      else
         set_line("Tutor 5 no ha calificado")
      end
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

    return [tutors,grades,sum,quorum]
  end

  ## Define acceso a la activación de la inscripción para el alumno
  def get_access(ts,counter,reprobadas,calificadas)
    s    = ts.student
    term =   ts.term
    ## si el numero de reprobadas es menor a 2 accesamos
    if reprobadas < 2
      if s.program.level.to_i.eql? 2
        if counter.nil?
          set_line("El alumno #{s.full_name} es de doctorado y no registra materias por lo que nos disponemos a analizar sus evaluaciones para el ciclo #{term.name}")
          return doc_advance_term(term,s)
        else
          counter = counter + 1
          set_line("El alumno #{s.full_name} esta inscrito a #{counter} materias de las cuales se han calificado #{calificadas}")
          if counter.eql? calificadas
            return true
          else
            return false
          end
        end
      else
        if counter.nil?
          set_line("El alumno #{s.full_name} no curso ninguna materia pero aun asi fue inscrito al ciclo")
          return false
        else
          counter = counter + 1
          set_line("El alumno #{s.full_name} esta inscrito a #{counter} materias de las cuales se han calificado #{calificadas}")
          if counter.eql? calificadas
            return true
          else
            return false
          end
        end ## if counter
      end # if level
    else ## Si las reprobadas son 2 o mas avisamos de la baja
      staff   = Staff.find(s.supervisor).email
      set_line("El alumno #{s.full_name} sera dado de baja del programa #{s.program.name}")
      ## Enviar correo asesor y a Sandra y al mismo alumno
      content = "{:full_name=>\"#{s.full_name}\",:email=>\"#{s.email}\",:view=>2}"
      send_mail(staff.email,"Baja de alumno",content)
      send_mail("sandra.beltran@cimav.edu.mx","Baja de alumno",content)
      send_mail(s.email,"Baja de alumno",content)
      send_mail(s.email_cimav,"Baja de alumno",content)
      return false
    end #if reprobadas
  end  ## get_access
__END__
