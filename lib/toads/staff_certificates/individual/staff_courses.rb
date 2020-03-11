module Toads
  module StaffCertificates
    module Individual
      class StaffCourses < Toads::StaffCertificates::Basic

        def contenido
          term_course_schedules = @options[:term_course_schedules]
          staff                 = @options[:staff]
          start_date            = @options[:start_date]
          end_date              = @options[:end_date]
         
         
          @options[:line_breaks][:content].times do 
            @pdf.text "\n"
          end
                   
          data = []
          data << [{:content => "<b>Curso</b>", :align => :center}, {:content => "<b>Inicio</b>", :align => :center}, {:content => "<b>Fin</b>", :align => :center}, {:content => "<b>Horas Impartidas</b>", :align => :center}]
         
          text = "Por medio de la presente tengo el agrado de extender la presente constancia #{staff.ggender("genero")} <b>#{staff.title} #{staff.full_name}</b> quien participó impartiendo las siguientes asignaturas en el periodo <b>#{start_date.year}-#{end_date.year}</b>:\n\n"
         
          @pdf.text text, :align=>:justify, :inline_format=>true              
 
          term_course_schedules.each_with_index do |tcsch,index|
            if tcsch.term_course.nil?
              ## si el term_course ya no existe es que hay registros colgados
              ## simplemente los ignoramos y pasamos al siguiente
              next
            end #if tcsch.term_course.nil?

                      
            term_course = tcsch.term_course
            # El conteo se hace en un hash {k,v} donde k es el docente y v son las horas impartidas
            staff_hours = Hash.new(0)
           
            ::TermCourseSchedule.where(:staff_id=>staff.id,:term_course_id=>tcsch.term_course_id,:status=>1).each do |tcs2|
              hours_per_day = tcs2.end_hour.strftime("%H").to_i - tcs2.start_hour.strftime("%H").to_i 

              if staff_hours[staff.id].eql? 0
                @tcs2_sd = tcs2.start_date
              end 

              @tcs2_ed = tcs2.end_date
              days = (tcs2.start_date..@tcs2_ed).to_a.select {|k| [tcs2.day].include?(k.wday)}.size
             
              staff_hours[staff.id] += hours_per_day * days
            end #::TermCourseSchedule.where

            if !tcsch.nil?
              if @options[:ranges]
                if (term_course.term.start_date.between?(@options[:start_date],@options[:end_date]))||(term_course.term.end_date.between?(@options[:start_date],@options[:end_date]))
                  term_month = get_month_name(@tcs2_sd.month)
                    
                  course_name = "#{term_course.course.name}"
                  start_date  = {:content=>@tcs2_sd.strftime("%-d de #{term_month} de %Y"), :align=>:center}
                    
                  term_month = get_month_name(@tcs2_ed.month)
                  end_date    = {:content=>@tcs2_ed.strftime("%-d de #{term_month} de %Y"), :align=>:center}

                  hours       = {:content=>staff_hours[staff.id].to_s, :align=>:center}
                    
                  data << [course_name, start_date, end_date , hours]
                 end
               else
                 course_name = term_course.course.name
                 start_date  = {:content=>term_course.term.start_date.strftime("%-d de #{term_month} de %Y"),:align=>:center}
                 end_date    = {:content=>term_course.term.end_date.strftime("%-d de #{term_month} de %Y"),:align=>:center}
        
                 hours       = ""
                    
                 data << [course_name, start_date, end_date , hours]
               end
             end  ## multiples ifs
           
          end #@term_course_schedules.each_with_index

          tabla = @pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [190, 127,127,56])
          tabla.draw
        end #def contenido
       
        def render  ## sobreescribimos render
        end
       
      end #class StaffCourses
    end #module Individual
  end #module Certificate
end #module Toads