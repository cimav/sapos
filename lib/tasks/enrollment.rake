# coding: utf-8
namespace :enrollment do
  desc "Include closing term and enrollment tasks"
  @counter_alumnos = 0
  @counter_no      = 0
  @counter_si      = 0

  ############################### CHECK ############################
  task :check, [:option] => :environment do |t,args|
    set_line("===== Iniciando script enrollment:check =====")
    ## nos traemos todos los ciclos que estan finalizados
    if args[:option].eql? "terms"
      puts "#####################{CICLO}"
      terms = Term.joins(:program).where("programs.level in (1,2) AND terms.name like '%#{CICLO}%'")
      terms.each do |t|
        puts "#{t.status} |#{(t.status.to_i.in? [3,4]) ? 'OK!' : 'XXX'} | #{t.name} | #{t.program.name}"
      end
    end
    
    set_line("===== Finalizando script enrollment:check =====")
  end#task check
 
  ############################### RUN  ############################
  task :run => :environment do
    set_line("===== Iniciando script enrollment:check =====")

    terms = Term.joins(:program).where("programs.level in (1,2) AND terms.name like '%#{CICLO}%'")

    if terms.size.eql? 0 then
      set_line("No hay cierres de calificaciones")
    else
      set_enrollment(terms)
    end
    set_line("===== Finalizando script enrollment:check =====")
  end#task run
end#namespace
########################################## METHODS ################################################

def set_enrollment(terms)
  alumnos              = Hash.new
  alumnos[:total]      = 0
  alumnos[:errors]     = Array.new
  alumnos[:avg]        = 0

  s_nciclo = TermStudent.select("students.id as id").joins(:student).joins(:term).where(:students=>{:status=>1}).where("terms.name like '%#{NCICLO}%'").map {|ts| ts.id}

  terms.each do |t|
     set_line("====== PROGRAMA ==========")
     set_line("====== #{t.program.name}")
     set_line("====== #{t.name}")
     
     ## estudiantes inscritos en el nuevo ciclo, metemos los ids en un array
     s_nciclo = TermStudent.select("students.id as id").joins(:student).joins(:term).joins(:term=>:program).where(:students=>{:status=>1}).where("terms.name like '%#{NCICLO}%'").where("programs.level in (?)",[1,2]).map {|i| i.id}

     ## Alumnos activos en ese ciclo y que no esten activos en el otro
     tss = TermStudent.joins(:student).where(:term_id=>t.id,:students=>{:status=>1}).where("students.id not in (?)",s_nciclo)
     ## Vamos revisando alumno por alumno (i1)
     tss.each_with_index do |ts,i1|
       @full_name = ts.student.full_name
       set_line("==== ALUMNO ==== ")
       set_line("==== #{@full_name}")
       check_enrollment_courses(ts,alumnos)
       chae    = nil
       

       if alumnos[:errors].size > 0
         alumnos[:errors].each do |e|
           set_line(e[:desc])
           if e[:code].eql? 3
             if check_advance_enrollment(ts.term,ts.student)
               chae = e
             end
           end
         end
       end

       if !chae.nil?
         alumnos[:errors].delete(chae)
         chae = nil
       end
   
       if alumnos[:errors].size > 0
         set_line("No se activa la inscripción para #{@full_name}")
         @counter_no = @counter_no + 1
       else
         set_line("Activando inscripción para #{@full_name}")
         @counter_si      = @counter_si + 1
          ## colocar estatus de pre-inscrito
         if STATUS_CHANGE
           ts.student.status = Student::PENROLLMENT
           ts.student.save
         end

         ## Enviar correos para eleccion de materias
         if ts.student.email_cimav.empty?
           set_line("No se pudo enviar correo a #{@full_name}")
         else
           prom    = alumnos[:avg]
           set_line("Promedio: #{prom.to_s}")
           content = "{:ciclo=>\"#{NCICLO}\",:view=>8}"
=begin
           staff   = Staff.find(ts.student.supervisor) rescue nil

           if staff 
             content = "{:full_name=>\"#{@full_name}\",:email=>\"#{ts.student.email_cimav}\",:view=>1,:avg=>\"#{prom}\"}"
             send_mail(staff.email,"Alumno preparado para la inscripcion",content)
           else
             set_line("No se encuentra director de tesis registrado")
           end
=end

           send_mail(ts.student.email_cimav,"Inscripción al ciclo #{NCICLO}",content)
         end
       end
       ## resetear errores y promedio antes de continuar con el sig. alumno
       alumnos[:errors]     = Array.new
       alumnos[:avg]        = 0
     end #tss.each_with_index
  end#term.each

  set_line("=========================================================")
  set_line("El numero de alumnos analizados fue #{alumnos[:total]}")
  set_line("No se activaron: #{@counter_no}")
end #def set_enrollment

def check_enrollment_courses(ts,alumnos)
  alumnos[:total] = alumnos[:total] + 1
  t_c_s = ts.term_course_student.where(:status=>1,:students=>{:status=>1}) 
  if t_c_s.size>0
    counter_total = 0
    acumulador    = 0
    ## recorremos cada materia a la que esta inscrito para el ciclo anterior
    t_c_s.each_with_index do |tcs,i2|
      tcs_grade = tcs.grade
      set_line("#{i2} | #{tcs.term_course.course.name} | #{tcs.grade} ")
      if tcs.grade.nil?
        alumnos[:errors] << {:code=>1,:desc=>"Materia sin calificar"}
      elsif tcs_grade < 70
        alumnos[:errors] << {:code=>2,:desc=>"Materia reprobada"}
      else
        acumulador = acumulador + tcs_grade.to_i
        counter_total = counter_total + 1
      end## if
    end# t_c_s
  else
    alumnos[:errors] << {:code=>3,:desc=>"El alumno no curso ninguna materia pero aún asi fue inscrito al ciclo"}
  end

  if alumnos[:errors].size.eql? 0
    alumnos[:avg] = acumulador / counter_total
  end
end #def check_enrollment_courses

def check_advance_enrollment(term,student)
    advances = student.advance.where("advances.advance_date between ? and ? and advances.status in (?)",term.start_date,term.end_date,['P','C'])

    set_line("SIZE: #{advances.size}")
    if advances.size > 0
      set_line("#{advances.size} avances sin materias encontrados")
      t_g = get_tutors_and_grades(advances[0],term)
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
        end
      end
    else
      set_line("No se encontro ningun avance")
      return false
    end
end #def check_advance_enrollment
