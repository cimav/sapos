module Toads
  module StaffCertificates
    module Individual
      class ThesisDirector< Toads::StaffCertificates::Basic    
        def initialize(options)
          options[:margin] = [0,60,60,60]
          options[:line_breaks] = {:begining=>0,:correspondence=>2,:content=>2,:carefully=>2,:sign=>1}
          super(options)
        end
       
        def contenido   
          @options[:line_breaks][:content].times do 
            @pdf.text "\n"
          end
         
          staff   = @options[:staff]
          student = @options[:student]
         
          if staff.id.eql? student.supervisor
            description = "<b>Director de Tesis</b>"
          elsif staff.id.eql? student.co_supervisor
            description = "<b>Co-Director de Tesis</b>"
          elsif staff.id.eql? student.external_supervisor
            description = "<b>Director Externo</b>"
          else
            description = "<b>INDEFINIDO</b>"
          end
         
        #  if student.status.eql? 1 #activo
            docente = "Por medio de la presente tengo el agrado de extender la presente constancia #{staff.ggender("genero3")} <b>#{staff.title} #{staff.full_name}</b>"

            if student.program.level.to_i.eql? 2 #doctorado
              if student.thesis.title.blank?
                text = "\n\n<font size='20'><b>El sistema ha detectado el título vacío de la tesis del alumno: #{student.full_name.lstrip.rstrip}</b></font>"
              else
                periodo = "quien desde el <b>#{student.start_date.day} de #{get_month_name(student.start_date.month)} de #{student.start_date.year}</b> funge como"
                alumno_tesis = "#{student.ggender("genero4")} alumn#{student.ggender("genero")} <b>#{student.full_name.lstrip.rstrip}</b>"
              
                text = "#{docente} #{periodo} #{description} #{alumno_tesis}."
              end # if tesis en blanco
            else #maestria u otro
              if student.is_first_grade
                periodo =  "quien desde el <b> #{student.start_date.day} de #{get_month_name(student.start_date.month)} del #{student.start_date.year}</b> funge como"
                alumno_tesis = "#{student.ggender("genero4")} alumn#{student.ggender("genero")} <b>#{student.full_name.lstrip.rstrip}</b> matricula #{student.card} de nuestro programa de #{student.program.name}."
                text = "#{docente} #{periodo} #{description} #{alumno_tesis}"
              else
                periodo =  "quien desde el <b> #{student.start_date.day} de #{get_month_name(student.start_date.month)} del #{student.start_date.year}</b> funge como"
                alumno_tesis = "#{student.ggender("genero4")} alumn#{student.ggender("genero")} <b>#{student.full_name.lstrip.rstrip}</b> matricula <b>#{student.card}</b> de nuestro programa de <b>#{student.program.name}</b>, con la Tesis: \"#{student.thesis.title.lstrip.rstrip rescue ""}\"."
                text = "#{docente} #{periodo} #{description} #{alumno_tesis}."
              end
            end #if doctorado o maestria
 #         end # if estudiante activo
         
          @pdf.text text, :inline_format=>true, :align=>:justify
        end ##def contenido
       
        ## sobreescribimos order sin pie porque se supone que son de una sola página
        #

        def order
          self.cabecera
          self.correspondencia
          self.contenido
          self.final
        end
        
      

      end #class ThesisDirector
    end #module Individual
  end #module Certificate
end #module Toads
