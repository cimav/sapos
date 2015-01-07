# coding: utf-8
namespace :grades do
  desc "Grades Close at end of term"
  filep     = "#{Rails.root}/log/inscripciones.log"
  @f        = File.open(filep,'a')
  @env      = Rails.env
  SEND_MAIL = true

  ##################################################################################################################################
  #####                                           TASK CHECK                                                                   #####
  ##################################################################################################################################
  task :check => :environment do
    set_line("Iniciando script")
    #### NIVELES:
    # level (1) maestria, (2) doctorado, (3) propedeutico
    # Primero confirmamos los alumnos de maestria, luego doctorado que requiere otras confirmaciones
    # Ciclos en estatus de Calificando y con fecha de calificación al dia de la ejecucion del script
    terms = Term.joins(:program).where("status=3 AND grade_end_date=CURDATE() AND programs.level in (1,2)")


    if terms.size.eql? 0 then
      set_line("No hay cierres de calificaciones")
    else
      terms.each do |t|
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
          ts.term_course_student.where(:status=>1).each_with_index do |tcs,i2|
            if !tcs.grade.nil?
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
          if get_access(ts.student,counter,reprobadas,calificadas)
            set_line("Activando inscripción para #{ts.student.full_name}")
            ## Le ponemos al alumno el estatus de p_enrollment(pending enrollment)
            ts.student.status = Student::PENROLLMENT
            ts.student.save
            ## Enviamos correo a su asesor
            staff   = Staff.find(ts.student.supervisor)
            if staff.email.empty?
              set_line("No se pudo enviar correo a #{staff.full_name}")
            else
              content = "{:full_name=>\"#{ts.student.full_name}\",:email=>\"#{ts.student.email}\",:view=>1}"
              send_mail("enrique.turcott@cimav.edu.mx","Alumno preparado para la inscripcion",content) #DEV
              #send_mail(staff.email,"Alumno preparado para la inscripcion",content)  ## PROD
            end ## staff.empty
          else
            set_line("No se activa la inscripción para #{ts.student.full_name}")
          end ## get_access
        end ## tss
      end  ## terms.each
    end ## if terms.size

    set_line("Finalizando script")
  end ## task grades

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
    if SEND_MAIL
      if to.nil?
        set_line("Error, email vacio. #{content}")
      else
        mail    = Email.new({:from=>"atencion.posgrado@cimav.edu.mx",:to=>to,:subject=>subject,:content=>content,:status=>0})
        mail.save
        set_line("Enviando correo a #{to}")
      end
    else
        set_line("Enviando correo a #{to} [DESACTIVADO]")
    end ## SEND_MAIL
  end

  ## revisa si ya se califico todo el avance de investigación de doctorado
  def doc_advance(s)
    if s.program.level.to_i.eql? 2
      return false
    else
      return true
    end
  end

  ## Define acceso a la activación de la inscripción para el alumno
  def get_access(s,counter,reprobadas,calificadas)
    ## si el numero de reprobadas es menor a 2 accesamos
    if reprobadas < 2
      if s.program.level.to_i.eql? 2
        #set_line("No se ha calificado el avance de investigacion #{ts.student.full_name}")
        return true
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
      ## DEV
      send_mail("enrique.turcott@cimav.edu.mx","Baja de alumno",content)
      ## PROD
      #send_mail(staff.email,"Baja de alumno",content)
      #send_mail("sandra.beltran@cimav.edu.mx","Baja de alumno",content)
      #send_mail(s.email,"Baja de alumno",content)
      #send_mail(s.email_cimav,"Baja de alumno",content)
      return false
    end #if reprobadas
  end  ## get_access

  ##################################################################################################################################
  #####                                              TASK ALARM                                                                #####
  ##################################################################################################################################
  task :alarm => :environment do
    ## comprobar si falta una semana para calificaciones
    advances = Advance.joins(:student=>[:term_students=>:term]).joins(:student=>:program).where("terms.status=? AND terms.grade_start_date=date_sub(curdate(), INTERVAL 7 DAY) AND programs.level in (?) AND advance_date>terms.start_date AND advance_date<terms.end_date",3,[1,2]).select("advances.*,terms.id as terms_id")
    counter = 1
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
            content = "{:advance=>\"#{a.id}\",:view=>3}"
          else
            token = Token.new
            token.attachable_id     = t1.id
            token.attachable_type   = t1.class.to_s
            token.token             = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
            token.status            = 1
            token.expires           = Term.find(a.terms_id).grade_end_date
            token.save
            content = "{:advance=>\"#{a.id}\",:staff=>\"#{t.id}\",:token=>\"#{token.token}\",:view=>4}"
          end
          # DEV
          send_mail("enrique.turcott@cimav.edu.mx","Alerta Calificaciones",content)
          ## PROD
          #send_mail(t.email,"Alerta Calificaciones",content)
        end
      end

      counter = counter + 1
    end

    # buscar asesores con alumnos en fechas


  end ## task alarm

end ## namespace

__END__
