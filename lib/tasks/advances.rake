# coding: utf-8
namespace :advances do
  desc "Include closing advances tasks"

  ############################### CHECK ############################
  task :check => :environment do
    @yaenciclo= false

    set_line("===== Iniciando script advances:check =====")

    terms = Term.joins(:program).where("programs.level in (1,2) AND terms.name like '%#{CICLO}%'")
    
    if terms.size.eql? 0 then
      set_line("No hay programas dados de alta para el ciclo #{CICLO}")
    else
       set_line("Programas activos para el ciclo #{CICLO}")
       terms.each do |t|
         set_line("#{t.name} | #{t.program.name} | #{t.start_date.to_s} | #{t.end_date.to_s} | #{t.status.to_s} | #{(t.status.to_i.in? [3,4]) ? 'OK!' : 'FAIL'}")
       end
    end

    set_line("===== Finalizando script advances:check =====")
  end#task check

  ############################### RUN ############################
  task :run => :environment do 
    
    set_line("===== Iniciando script advances:run =====")
    terms = Term.joins(:program).where("programs.level in (1,2) AND terms.name like '%#{CICLO}%' AND status in (3,4)")
    alumnos              = Hash.new
    alumnos[:total]      = 0
    alumnos[:faltantes]  = 0
    alumnos[:acumulado]  = 0

    if terms.size.eql? 0 then
      set_line("No hay cierres de calificaciones")
    else
       set_line("Revisando programas activos")

       terms.each do |t|
         set_line("========== PROGRAMA ==========")
         set_line("#{t.name} | #{t.program.name}")
         ## Alumnos activos en este ciclo
         tss = TermStudent.joins(:student).where(:term_id=>t.id,:students=>{:status=>1})
         ## recorremos alumno por alumno
         tss.each_with_index do |ts,i1|
           @full_name = ts.student.full_name
           set_line("===== ALUMNO ===== ")
           set_line(@full_name)
           ## en esta funcion recorremos las materias de cada alumno
           check_courses(ts,alumnos)

           ## si tiene fallas acumuladas no se hizo el proceso
           if alumnos[:acumulado] > 0
             set_line("FAIL !!")
             alumnos[:faltantes] += 1
           ## si no todo esta bien
           else
             set_line("TODO OK !!")
           end

           alumnos[:acumulado]  = 0
         end##tss.each_with_index
       end## terms.each
    end##if-else terms.size

    set_line("Alumnos totales: #{alumnos[:total]}")
    set_line("Alumnos faltantes: #{alumnos[:faltantes]}")
    set_line("===== Finalizando script advances:run =====")
  end## task run
######################################################
end## namespace

########################################## METHODS ################################################

def check_courses(ts,alumnos)
  avances         = 0
  alumnos[:total] = alumnos[:total] + 1
  ## recorriendo materias a las que está inscrito para el ciclo escolar
  ts.term_course_student.where(:status=>1,:students=>{:status=>1}).each_with_index do |tcs,i2|
    ## buscando las que son de investigacion [AI] y devolviendo promedio
    tcs_grade = get_tcs_grade(ts,tcs)
    
    ## si la materia es de investigacion y tiene el tcs_grade vuelve null
    if tcs_grade[:ai] and tcs_grade[:grade].nil?
      set_line("#{i2} | M.INVESTIGACION | #{tcs.term_course.course.name} | #{tcs.grade} ")
      #set_line("Avance no encontrado o sin quorum")
      alumnos[:acumulado] += 1
    ## si la materia es de investigacion y esta reprobado
    elsif tcs_grade[:ai] and (tcs_grade[:grade] <= 70)
      set_line("#{i2} | MAT.INVESTIGA | #{tcs.term_course.course.name} | #{tcs.grade} ")
      set_line("Avance reprobado")
      ## en realidad no es pedo de avances sino del proceso de inscripcion
      #alumnos[:acumulado] += 1
    ## la materia es de investigacion y esta aprobado
    elsif tcs_grade[:ai] and (tcs_grade[:grade] > 70)
      set_line("#{i2} | MAT.INVESTIGA | #{tcs.term_course.course.name} | #{tcs.grade} ")
      #set_line("Materia de Investigación ya revisada y/o aprobada")
    ## si simplemente la calificacion vuelve en nulo
    elsif tcs_grade[:grade].nil?
      set_line("#{i2} | MATERIA NORMAL | #{tcs.term_course.course.name} | #{tcs.grade} ")
      ## en realidad no nos interesa acumularla aunque este reprobada porque no es parte de el proceso de avances sino de inscripcion
      ## pero en dado caso de que necesitemos diferenciarla la dejamos en el elsif
      #alumnos[:acumulado] += 1
    else
      set_line("#{i2} | MATERIA NORMAL | #{tcs.term_course.course.name} | #{tcs.grade} ")
      #set_line("Al parecer todo esta OK")
    end# tcs_grade
  end#ts.term_course_student
  return alumnos
end#check_advance_advance

############################################## ########################################################################
def get_tcs_grade(ts,tcs)
  level     = ts.student.program.level.to_i
  if level.to_i.eql? 2 and tcs.term_course.course.notes.eql? "[AI]"
    set_line("Alumno de doctorado y materia de avance de investigacion [AI]")
    tcs_grade = set_tcs_values(tcs,level,true)
  elsif level.to_i.eql? 1 and tcs.term_course.course.notes.eql? "[AI]"
    set_line("Alumno de maestria y materia de avance de investigacion [AI]")
    tcs_grade = set_tcs_values(tcs,level,true)
  else
    tcs_grade = set_tcs_values(tcs,level,false)
  end#if/elsif
  
  return tcs_grade
end#confirm_level

############################################## ########################################################################
def set_tcs_values(tcs,level,ai) 
  tcs_grade = Hash.new
  ## solo si es avance de investigacion y materia AI busca el avance
  if ai
    tcs_grade[:grade] = check_advance(tcs)  
  else
    tcs_grade[:grade] = nil
  end
  tcs_grade[:level] = level
  tcs_grade[:ai]    = ai

  return tcs_grade
end# set_tcs_values
