module Toads
  module StaffCertificates
    module Individual
      class TutoralCommittee < Toads::StaffCertificates::Basic    
       
       def contenido
        @options[:line_breaks][:content].times do 
          @pdf.text "\n"
        end
        
         advance = @options[:a]
         staff   = @options[:staff]
        
         docente =  "\nPor medio de la presente tengo el agrado de extender la presente constancia #{staff.ggender("genero3")} <b>#{staff.title} #{staff.full_name}</b>"
         texto = "#{docente} quien participó como parte del comité tutoral del alumno <b>#{advance.student.full_name}</b> alumno inscrito en nuestro programa de <b>#{advance.student.program.name}</b>."
        
         @pdf.text texto, :align=>:justify, :inline_format=>true           

       end
 
        ## sobreescribimos order sin pie porque se supone que son de una sola página
        def order
          self.cabecera
          self.correspondencia
          self.contenido
          self.final
        end


      end #class TutoralCommittee
    end #module Individual
  end #module Certificate
end #module Toads