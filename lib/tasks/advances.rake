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
       set_line("Revisando programas activos")
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

    @counter_alumnos = 0

    if terms.size.eql? 0 then
      set_line("No hay cierres de calificaciones")
    else
       set_line("Revisando programas activos")

       terms.each do |t|
         set_line("===== PROGRAMA =====")
         set_line("#{t.name} | #{t.program.name}")
         ## Alumnos activos en este ciclo
         tss = TermStudent.joins(:student).where(:term_id=>t.id,:students=>{:status=>1})
         tss.each_with_index do |ts,i1|
           @full_name = ts.student.full_name
           set_line("===== ALUMNO ===== ")
           set_line(@full_name)
           check_advance_advance(ts)
         end##tss.each_with_index
       end## terms.each
    end##if-else terms.size
    set_line("===== Finalizando script advances:run =====")
  end## task run
######################################################
end## namespace

########################################## METHODS ################################################

def check_advance_advance(ts)
  avances        = 0
  @counter_alumnos = @counter_alumnos + 1
  ## recorriendo materias a las que está inscrito para el ciclo escolar
  ts.term_course_student.where(:status=>1,:students=>{:status=>1}).each_with_index do |tcs,i2|
    ## buscando las que son de investigacion [AI] y devolviendo promedio
    tcs_grade = confirm_level(ts,tcs)

    ## si devuelve nulo es que no es materia de investigación
    if tcs_grade.nil? 
      set_line("#{i2} | Materia Normal | #{tcs.term_course.course.name} | #{tcs.grade} ")
    else
      ## si es de investigacion guardamos el promedio en la misma materia
      if STATUS_CHANGE
        tcs.grade = tcs_grade
        tcs.save
        set_line("#{i2} | Materia de Inv | #{tcs.term_course.course.name} | #{tcs.grade} ")
      end
    end
  end#ts.term_course_student
end#check_advance_advance

def confirm_level(ts,tcs)
  level     = ts.student.program.level.to_i
  if level.to_i.eql? 2 and tcs.term_course.course.notes.eql? "[AI]"
    set_line("Alumno de doctorado y materia de avance de investigacion [AI]")
    tcs_grade = check_advance(tcs)  
  elsif level.to_i.eql? 1 and tcs.term_course.course.notes.eql? "[AI]"
    set_line("Alumno de maestria y materia de avance de investigacion [AI]")
    tcs_grade = check_advance(tcs)  
  end#if/elsif
  
  return tcs_grade
end#confirm_level
