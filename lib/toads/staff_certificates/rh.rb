module Toads
  module StaffCertificates
    class RH < Toads::StaffCertificates::Basic
      def initialize(options)
        options[:margin]      = [120,55,134,55]  #[120,55,115,55]
        options[:line_breaks] = {:begining=>2,:correspondence=>1,:content=>1,:carefully=>2,:sign=>2}
        super(options)
      end
     
      def contenido 
       start_date = @options[:start_date]
       end_date   = @options[:end_date]
       staff      = @options[:staff]

       text = "\nPor medio de la presente tengo el agrado de extender la presente constancia #{staff.ggender("genero3")} <b>#{staff.title} #{staff.full_name}</b> quien participó en la formación de recursos humanos en el periodo del <b>#{start_date.day} de #{get_month_name(start_date.month)} del #{start_date.year}</b> al <b>#{end_date.day} de #{get_month_name(end_date.month)} del #{end_date.year}</b> de los siguientes estudiantes:"
       @pdf.text text, :align=>:justify, :inline_format=>true
       extra_newline = ""
        # Alumnos como director de tesis
        @students = @options[:active_students]
        @graduate_students = @options[:graduate_students]
        if @students.size > 0
          data = []
          data_helper = []
          data << [{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>FECHA DE TITULACIÓN</b>", :align => :center}]

          @students.each do |s|
            if s.status.in? [2,5] ## para egresados mostramos fecha de defensa
              defence_month = self.get_month_name(s.thesis.defence_date.month)
              data << [s.full_name, s.program.name, s.thesis.defence_date.strftime("%-d de #{defence_month} de %Y")]
            else
              data << [s.full_name, s.program.name,Student::STATUS[s.status]]
            end
          end

          @pdf.text extra_newline
          @pdf.text "\n<b>Participación como director de tesis</b>\n", :align => :center, :inline_format => true
          tabla = @pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center)
          tabla.draw
        end

        # Alumnos como co-director de tesis
        @students = @options[:active_students_co]
        @graduate_students = @options[:graduate_students_co]
        if @students.size > 0
          data = []
          data << [{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>FECHA DE TITULACIÓN</b>", :align => :center}]

          @students.each do |s|
            if s.status.in? [2,5] ## para egresados mostramos fecha de defensa
              defence_month = self.get_month_name(s.thesis.defence_date.month)
              data << [s.full_name, s.program.name, s.thesis.defence_date.strftime("%-d de #{defence_month} de %Y")]
            else
              data << [s.full_name, s.program.name,Student::STATUS[s.status]]
            end
          end

          @pdf.text extra_newline
          @pdf.text "\n<b>Participación como co-director de tesis</b>\n", :align => :center, :inline_format => true
          tabla = @pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center)
          tabla.draw
        end

        # Alumnos como director externo
        @students = @options[:active_students_external]
        @graduate_students = @options[:active_students_external]
        if @students.size > 0
          data = []
          data << [{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>ESTATUS</b>", :align => :center}]

          @students.each do |s|
            data << [s.full_name, s.program.name, Student::STATUS[s.status]]
          end

          @pdf.text extra_newline
          @pdf.text "\n<b>Participación como director externo</b>\n", :align => :center, :inline_format => true
          tabla = @pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center)
          tabla.draw
        end


        # tesis como sinodal
        @theses = @options[:theses]

        if @theses.size > 0
          data = []
          data << [{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>FECHA DE DEFENSA</b>", :align => :center}]

          @theses.each do |t|
            defence_month = self.get_month_name(t.defence_date.month)
            data << [t.student.full_name, t.student.program.name, t.defence_date.strftime("%-d de #{defence_month} de %Y")]
          end

          @pdf.text extra_newline
          @pdf.text "\n<b>Participación como sinodal</b>\n", :align => :center, :inline_format => true
          #@pdf.text "<b>Participación como sinodal</b>\n", :align => :center, :inline_format => true

          tabla = @pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [190, 190, 120])
          tabla.draw
        end

        # avances como comité tutoral de Avance Programático
        active_advances = []
        active_advances = @options[:advances]
      
        if active_advances.size > 0
          data = []

          approved = false
          nombre_anterior = nil
          program_id_anterior = nil

          active_advances.each do |a|
            if ((nombre_anterior.eql? a.student.full_name_cap)&(program_id_anterior.eql? a.student.program_id))
              approved = false
            else
              approved = true
            end

            if approved
              advance_month = self.get_month_name(a.advance_date.month)
              data << [a.student.full_name_cap, a.student.program.name, a.advance_date.strftime("%-d de #{advance_month} de %Y"), a.advance_date]
            
              nombre_anterior     = a.student.full_name_cap
              program_id_anterior = a.student.program_id
            end
          end 

          ## ordenando por la tercera fila que es la fecha directo de db
          data.sort!{|x,y|x[3]<=>y[3]}
          ## eliminando el registro de fecha de cada fila porque sino truena la tabla
          data.each do |d|
            d.delete_at(3)
          end

          ## insertando cabecera con unshift
          data.unshift([{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>FECHA DE AVANCE</b>", :align => :center}])

          @pdf.text extra_newline
          @pdf.text "\n<b>Participación como comité tutoral</b>\n", :align => :center, :inline_format => true
          tabla = @pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [190, 190, 120])
          tabla.draw
        end

        # Seminaros departamentales como comité tutoral         
        @seminars = @options[:seminars]
        
        if @seminars.size > 0
          data = []
          data << [{:content => "<b>NOMBRE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>FECHA DE AVANCE</b>", :align => :center}]

          @seminars.each do |s|
            advance_month = self.get_month_name(s.advance_date.month)
            data << [s.student.full_name, s.student.program.name, s.advance_date.strftime("%-d de #{advance_month} de %Y")]
          end

          @pdf.text extra_newline
          @pdf.text "\n<b>Seminarios departamentales</b>\n", :align => :center, :inline_format => true
          tabla = @pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [190, 190, 120])
          tabla.draw
        end

        # clases impartidas
        @term_course_schedules = @options[:term_course_schedules]

        if @term_course_schedules.size > 0
          data = []
          data << [{:content => "<b>CLASE</b>", :align => :center}, {:content => "<b>PROGRAMA</b>", :align => :center}, {:content => "<b>FECHA DE INICIO</b>", :align => :center}]

          @term_course_schedules.each do |tcs|
            puts "####### TERM_COURSE_SCHEDULE:#{tcs}|#{tcs.id}"
            term_course = tcs.term_course
            if !term_course.nil?
              puts "####### TERM COURSE: #{term_course.id}"
              if term_course.status != TermCourse::DELETED
                if @options[:ranges]
                  if (term_course.term.start_date.between?(@options[:start_date],@options[:end_date]))||(term_course.term.end_date.between?(@options[:start_date],@options[:end_date]))
                    term_month = self.get_month_name(term_course.term.start_date.month)
                    data << ["#{term_course.course.name}", term_course.term.program.name, term_course.term.start_date.strftime("%-d de #{term_month} de %Y")]
                  end
                else
                  term_month = self.get_month_name(term_course.term.start_date.month)
                  data << [term_course.course.name, term_course.term.program.name, term_course.term.start_date.strftime("%-d de #{term_month} de %Y")]
                end
              end
            else
              puts "################# TERM COURSE ESTA EN NIL!!"  
              #data << [tcs.id.to_s,"######","######"]
            end

          end #@term_course_schedules.each

          @pdf.text extra_newline
          @pdf.text "\n<b>Clases impartidas</b>\n", :align => :center, :inline_format => true
          tabla = @pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [190, 190, 120])
          tabla.draw
        end

        # Cursos o talleres
        @external_courses = @options[:external_courses]

        if @external_courses.size > 0
          data = []
          data << [{:content => "<b>TÍTULO</b>", :align => :center}, {:content => "<b>FECHA DE INICIO</b>", :align => :center}, {:content => "<b>TIPO</b>", :align => :center}]

          @external_courses.each do |e|
            course_month = self.get_month_name(e.start_date.month)
            data << [e.title, e.start_date.strftime("%-d de #{course_month} de %Y"), e.get_type]
          end

          @pdf.text extra_newline
          @pdf.text "\n<b>Cursos o talleres</b>\n", :align => :center, :inline_format => true
          tabla = @pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [300, 100, 100])
          tabla.draw
        end

        # Prácticas de laboratorio
        @lab_practices = @options[:lab_practices]

        if @lab_practices.size > 0
          data = []
          #self.get_month_name(time.month)
          data << [{:content => "<b>Título</b>", :align => :center}, {:content => "<b>FECHA DE INICIO</b>", :align => :center}, {:content => "<b>TIEMPO DE PRÁCTICA</b>", :align => :center}]

          @lab_practices.each do |l|
            practice_month = self.get_month_name(l.start_date.month)
            data << [l.title, l.start_date.strftime("%-d de #{practice_month} de %Y"), l.hours]
          end

          @pdf.text extra_newline
          @pdf.text "\n<b>Prácticas de laboratorio</b>\n", :align => :center, :inline_format => true
          tabla = @pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [280, 100, 120])
          tabla.draw

        end

        # Servicios CIMAV
        @internships= @options[:internships]
        
        if @internships.size > 0
          data = []
          data << [{:content => "<b>Nombre</b>", :align => :center}, {:content => "<b>Tipo de Servicio</b>", :align => :center}]          

          approved = false
          nombre_anterior = nil
          i_type_anterior = nil
          @internships.each do |i|
            if ((i_type_anterior.eql? i.internship_type_id)&&(nombre_anterior.eql? i.full_name_cap))
              approved = false
            else
              approved = true
            end

            if approved
              data << [i.full_name_cap, i.internship_type.name]
            
              nombre_anterior = i.full_name_cap
              i_type_anterior = i.internship_type_id
            end
          end 

          @pdf.text extra_newline
          @pdf.text "\n<b>Servicios CIMAV</b>\n", :align => :center, :inline_format => true
          tabla = @pdf.make_table(data, :width => 500, :cell_style => {:size => 9, :padding => 2, :inline_format => true, :border_width => 1}, :position => :center, :column_widths => [280, 220])
          tabla.draw
        end
      end
    end #class RH
  end #module Certificate
end #module Toads        
