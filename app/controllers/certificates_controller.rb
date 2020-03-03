# coding: utf-8
class CertificatesController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def total_studies_certificate
=begin 
  NOTAS
  @template_mode - esta variable se activa y desactiva manualmente cuando el usuario solicita machote de algun plan de estudios
                   hay que especificar manualmente el plan pero el titulo de la maestria no lo hace por lo que hay que
                   elegir un estudiante que sea del programa que necesitamos.
=end

    @template_mode  = false  ## leer NOTAS
    @r_root    = Rails.root.to_s
    t = Thesis.find(params[:thesis_id])
    libro     = params[:libro]
    foja      = params[:foja]
    duplicate = params[:duplicate]

    dir = t(:directory)
    avg = 0.0
    sum = 0.0
    @text_color = "000000" #373435
    #Prawn::Document.new(:top_margin => 20.0, :bottom_margin=> 20.0, :left_margin=>30.0, :right_margin=>30.0) do |pdf|
    Prawn::Document.new do |pdf|
      pdf.font_families.update("Times" => {
        :bold        => "#{@r_root}/private/fonts/times/timesbd.ttf",
        :italic      => "#{@r_root}/private/fonts/times/timesi.ttf",
        :bold_italic => "#{@r_root}/private/fonts/times/timesbi.ttf",
        :normal      => "#{@r_root}/private/fonts/times/times.ttf"
      })
      pdf.font_families.update("Arial" => {
        :bold        => "#{@r_root}/private/fonts/arial/arialbd.ttf",
        :italic      => "#{@r_root}/private/fonts/arial/ariali.ttf",
        :bold_italic => "#{@r_root}/private/fonts/arial/arialbi.ttf",
        :normal      => "#{@r_root}/private/fonts/arial/arial.ttf"
      })
      pdf.font "Times"

      ## SET CENTER IMAGE
      #image = "#{Rails.root}/private/images/logo_cimav_100.png"
      y = 690
      #pdf.image image, :at => [22,y], :height => 42
      ## SET CENTER TITLE
      x = 93
      w = 360
      h = 50

      pdf.fill_color @text_color
      ## SET FOLIO TITLE, LINE AND FOLIO
      # SET FOLIO TITLE
      x = 349
      y = y - 72
      w = 100
      h =  13
      size = 12
      text = "Certificado No."
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left
      
      
      if duplicate.to_i.eql? 1
        text = "Duplicado"
        pdf.text_box text , :at=>[x+50,y-11], :width => w, :height=> h, :size=>8, :style=> :bold, :align=> :left
      end
      ## SET FOLIO LINE
      y = y - 9
      pdf.stroke_color= @text_color
      pdf.line_width= 0.2
      pdf.stroke_line [x + 81,y],[485,y]
      ## SET FOLIO
      x = 440
      y = y + 8
      w = 40
      h = 13

      if @template_mode
        libro = "XX"
        foja = "XX"
      end

      text = "#{libro}-#{foja}"
      pdf.text_box text , :at=>[x,y + 2], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :center

      ## SET NAME AND PROGRAM NAME
      # SET NAME
      x = 46
      y = y - 54
      w = 550
      h = 13
      size = 14
 
      if @template_mode
        text = "Hace constar que XXXXXXXXXXXXXXXX"
      else
        text = "Hace constar que #{t.student.full_name.mb_chars}"
      end

     
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center
      # SET PROGRAM NAME
      y = y - 14
      w = 445
      h = 30
      size = 14
      text = "Cursó y acreditó: #{t.student.program.name.mb_chars}"
      pdf.text_box text , :at=>[x,y - 4] , :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center

      # SET ROLLOTE
      pdf.stroke_color= @text_color
      x = 158
      y = y - 78
      w = 310
      h = 80
      size = 12

      l = 3.8
      @size_box = 16
      pdf.bounding_box([x,y],:width=>w + 20, :height=>h + 33,:kerning=>true) do
        pdf.text "Conforme a los planes de estudio vigentes", :style=>:bold, :align=>:justify,:leading=>l,:character_spacing=>1.07, :size=>@size_box
        pdf.text "conservandose las evaluaciones", :style=>:bold, :align=>:justify,:leading=>l,:character_spacing=>3.923, :size=>@size_box
        pdf.text "de la totalidad de los programas vigentes", :style=>:bold, :align=>:justify,:leading=>l,:character_spacing=>1.2, :size=>@size_box
        pdf.text "en los archivos de esta Institución", :style=>:bold, :align=>:justify,:leading=>l,:character_spacing=>2.87, :size=>@size_box
      end

      # SET PHOTO
      pdf.line_width = 0.8
      y = y + 3
      x = 41
      w = 70
      h = 75
      pdf.stroke_rectangle [x,y],w,h
      pdf.text_box "Fotografía/n Tamaño Infantil", :at=>[x + 2,y - 2], :width => w - 3, :height=> h - 5, :size=>6, :style=> :bold, :align=> :center, :valign=> :center

      ## STUDENT SIGN
      x    = 30
      y    = y - 108
      x1   = 128
      pdf.stroke_line [x,y],[x1,y]
      x    = x + 16
      y    = y - 7
      w    = 100
      h    = 10
      size = 9
      text = "Firma del alumno"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left

      ## SET SUBTITLE
      x    = 109
      y    = y - 41
      w    = 300
      h    = 20
      size = 22
      text = "Certificado Total de Estudios"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :center

      set_lines(pdf,y - 33, 50)

 
      if @template_mode     
        # usualmente se utiliza esta linea y llegan las materias  de forma correcta
        #tcss  = Course.where(:program_id=>3,:studies_plan_id=>17).where("term not in (99,100,101)").order(:code)

        ## estas lineas son para el caso del plan 17 que trae desordenados los codes de las materias (se trae primero los blancos)
        tcss1 = Course.where(:program_id=>3,:studies_plan_id=>17).where("term=1").order("courses.term")
        tcss2 = Course.where(:program_id=>3,:studies_plan_id=>17).where("term=2").order("courses.term, courses.id desc")
        tcss3 = Course.where(:program_id=>3,:studies_plan_id=>17).where("term=3").order("courses.term, courses.id asc")
        tcss4 = Course.where(:program_id=>3,:studies_plan_id=>17).where("term=4").order("courses.term, courses.id desc")

        tcss = tcss1 + tcss2 + tcss3 + tcss4
      else
        order   = "terms.end_date"
        #order = "courses.code"
        if t.student.program.level.to_i.eql? 2 ## Doctorado
          where = "term_students.student_id=? AND term_course_students.status=? AND term_course_students.grade>=?"
          #tcss  = TermCourseStudent.joins(:term_student=>:term).joins(:term_course=>:course).where(where,t.student.id,TermCourseStudent::ACTIVE,70).order(order)
          tcss  = TermCourseStudent.includes(:term_student=>:term).includes(:term_course=>:course).where(where,t.student.id,TermCourseStudent::ACTIVE,70).order(order)
        else ## Maestria y otros
          where = "term_students.student_id=? AND term_course_students.status=? AND term_course_students.grade>=?"
          #tcss  = TermCourseStudent.joins(:term_student=>:term).joins(:term_course=>:course).where(where,t.student.id,TermCourseStudent::ACTIVE,70).order(order)  
          tcss  = TermCourseStudent.includes(:term_student=>:term).includes(:term_course=>:course).where(:status=>1).where(where,t.student.id,TermCourseStudent::ACTIVE,70).order(order)
        end
      end


      # if t.student.studies_plan_id.eql? 15 ## DCM - 2014 Actualizacion del plan de estudios
      #   my_select_topics_codes = ["101","201","301","401","501","601"]
      #   my_select_topics = [
      #       {:code=>"101",:name=>"Temas Selectos de Ciencia de Materiales 1"},
      #       {:code=>"201",:name=>"Temas Selectos de Ciencia de Materiales 2"},
      #       {:code=>"301",:name=>"Temas Selectos de Ciencia de Materiales 3"},
      #       {:code=>"401",:name=>"Temas Selectos de Ciencia de Materiales 4"},
      #       {:code=>"501",:name=>"Temas Selectos de Ciencia de Materiales 5"},
      #       {:code=>"601",:name=>"Temas Selectos de Ciencia de Materiales 6"},
      #     ]
       
      #   tcss.each do |tcs|        
      #     #if tcs.term_course.course.code.in? my_select_topics_codes
      #     #   my_select_topics_codes.shift
      #     #end 
          


      #     ## para las materias optativas de otros programas
      #     if !(tcs.term_course.course.program_id.eql? t.student.program_id)  
      #       puts tcs.term_course.course.name
      #       puts "-----------"          
      #       code = my_select_topics_codes.shift
      #       if !code.nil?
      #         msts = my_select_topics.select{|x| x[:code].eql? code}
      #         tcs.term_course.course.code = msts[0][:code]
      #         tcs.term_course.course.name = msts[0][:name]
      #         puts tcs.term_course.course.name
      #         puts "xxxxxxxxx" 
      #       else
      #         tcss.reject!{|object| object == tcs }
      #       end
      #     end

      #     ## para las materias complementarioas
      #     if tcs.term_course.course.term.to_i.eql? 101
      #       code = my_select_topics_codes.shift
      #       msts = my_select_topics.select{|x| x[:code].eql? code}
      #       tcs.term_course.course.code = msts[0][:code]
      #       tcs.term_course.course.name = msts[0][:name]
      #     end

      #   end #tcss.each 
      # end #if t.student.studies_plan_id.eql? 15

      #pdf.font "Arial"
      if tcss.size >= 16
        offset = 8
        # CODE INITIAL DATA
        x = 63
        y = 210 + offset
        w = 20
        h = 9
        size = 8
        # COURSE NAME INITIAL DATA
        x_1 = 107
        y_1 = y + 8 + offset
        w_1 = 106
        h_1 = 25
        size_1 = 8
        # TERMS INITIAL DATA
        x_2 = 220
        y_2 = y + offset - 10
        w_2 = 45
        h_2 = 9
        size_2 = 8
        # GRADE INITIAL DATA
        x_3 = 273
        y_3 = y + offset - 10
        w_3 = 38
        h_3 = 9
        size_3 = 8
        # GRADE ON TEXT INITIAL DATA
        x_4 = 317
        y_4 = y + offset -4
        w_4 = 82
        h_4 = 20
        size_4 = 8
      elsif tcss.size >= 14
        offset = 5
        # CODE INITIAL DATA
        x = 63
        y = 210 + offset
        w = 20
        h = 9
        size = 8
        # COURSE NAME INITIAL DATA
        x_1 = 107
        y_1 = y + 8 + offset
        w_1 = 106
        h_1 = 25
        size_1 = 8
        # TERMS INITIAL DATA
        x_2 = 220
        y_2 = y + 1 + offset
        w_2 = 45
        h_2 = 9
        size_2 = 8
        # GRADE INITIAL DATA
        x_3 = 273
        y_3 = y + offset
        w_3 = 38
        h_3 = 9
        size_3 = 8
        # GRADE ON TEXT INITIAL DATA
        x_4 = 317
        y_4 = y + 5 + offset
        w_4 = 82
        h_4 = 20
        size_4 = 8
      elsif tcss.size >= 11
        # CODE INITIAL DATA
        x = 63
        y = 210
        w = 20
        h = 9
        size = 8
        # COURSE NAME INITIAL DATA
        x_1 = 107
        y_1 = y + 8
        w_1 = 106
        h_1 = 25
        size_1 = 8
        # TERMS INITIAL DATA
        x_2 = 220
        y_2 = y + 1
        w_2 = 45
        h_2 = 9
        size_2 = 8
        # GRADE INITIAL DATA
        x_3 = 273
        y_3 = y
        w_3 = 38
        h_3 = 9
        size_3 = 8
        # GRADE ON TEXT INITIAL DATA
        x_4 = 317
        y_4 = y + 5
        w_4 = 82
        h_4 = 20
        size_4 = 8
      else
        # CODE INITIAL DATA
        x = 60
        y = 205
        w = 20
        h = 9
        size = 9
        # COURSE NAME INITIAL DATA
        x_1 = 108
        y_1 = y + 6
        w_1 = 106
        h_1 = 25
        size_1 = 9
        # TERMS INITIAL DATA
        x_2 = 220
        y_2 = y + 1
        w_2 = 45
        h_2 = 9
        size_2 = 9
        # GRADE INITIAL DATA
        x_3 = 273
        y_3 = y
        w_3 = 38
        h_3 = 9
        size_3 = 9
        # GRADE ON TEXT INITIAL DATA
        x_4 = 317
        y_4 = y + 5
        w_4 = 82
        h_4 = 18
        size_4 = 9
        # GENERAL DATA
        text = ""
      end

      counter = 0
      
      my_final_classes = Array.new

      if t.student.studies_plan_id.eql? 15  ##dcm15
        my_select_topics_codes = ["101","201","301","401","501","601","701"]
        my_select_topics = [
            {:code=>"101",:name=>"Temas Selectos de Ciencia de Materiales 1"},
            {:code=>"201",:name=>"Temas Selectos de Ciencia de Materiales 2"},
            {:code=>"301",:name=>"Temas Selectos de Ciencia de Materiales 3"},
            {:code=>"401",:name=>"Temas Selectos de Ciencia de Materiales 4"},
            {:code=>"501",:name=>"Temas Selectos de Ciencia de Materiales 5"},
            {:code=>"601",:name=>"Temas Selectos de Ciencia de Materiales 6"},
            {:code=>"701",:name=>"Temas Selectos de Ciencia de Materiales 7"},
          ]
        puts "ARRAY: #{my_select_topics.to_s}"
        s_program_id = t.student.program_id
        # ---------------------
        ## Primero limpiamos los temas selectos que y a estén en la base de datos
        tcss.each_with_index do |tcs,index|
          program_id  = tcs.term_course.course.program_id
          code =  tcs.term_course.course.code.mb_chars
          name =  tcs.term_course.course.name.mb_chars
          puts "CODE: #{code} #{name} #{program_id}|#{s_program_id}"
          if code.in? my_select_topics_codes
            my_select_topics_codes.delete(code)
            my_select_topics.delete_if { |a| a[:code]==code}
          end

        end
        puts "ARRAY2: #{my_select_topics.to_s}"
        puts "------------------------------"

        ## volvemos a recorrer para asignar cada materia optativa como tema selecto
        tcss.each_with_index do |tcs,index|
          my_final_class  = Hash.new
          program_id      = tcs.term_course.course.program_id
          code =  tcs.term_course.course.code.mb_chars
          name =  tcs.term_course.course.name.mb_chars
          puts "CODE: #{code} #{name} #{program_id}|#{s_program_id}"
 
          ## si no es del mismo programa entonces es una optativa
          if program_id != s_program_id
            topic = my_select_topics.shift
            my_final_class[:code] = topic[:code]
            my_final_class[:name] = topic[:name]
            puts "TOPIC: #{topic}"
          else
            
            my_final_class[:code] = code
            my_final_class[:name] = name
          end

          my_final_class[:term_name] = tcs.term_course.term.name
          my_final_class[:tcs_grade] = tcs.grade

          my_final_classes << my_final_class
        end

      else
        tcss.each_with_index do |tcs,index|
          my_final_class  = Hash.new
          code            =  tcs.term_course.course.code.mb_chars
          name            =  tcs.term_course.course.name.mb_chars

          my_final_class[:code] = code
          my_final_class[:name] = name
          my_final_class[:term_name] = tcs.term_course.term.name
          my_final_class[:tcs_grade] = tcs.grade

          my_final_classes << my_final_class
        end
      end #if t.student.studies_plan_id.eql? 15
      
      ## ordenamos tocho morocho
      my_final_classes.sort_by! {|obj| [obj[:term_name],obj[:code]]}

=begin
        if t.student.studies_plan_id.eql? 15  ##dcm15
          program_id  = tcs.term_course.course.program_id
          code =  tcs.term_course.course.code
          name =  tcs.term_course.course.name
          puts "CODE: #{code} #{name} #{program_id}|#{s_program_id}"
          if program_id != s_program_id
            topic = my_select_topics.shift
            tcs.term_course.course.code = topic[:code]
            tcs.term_course.course.name = topic[:name]
            puts "TOPIC: #{topic}"
          end
        end
=begin
            ## para las materias complementarioas
            if tcs.term_course.course.term.to_i.eql? 101
              code = my_select_topics_codes.shift
              msts = my_select_topics.select{|x| x[:code].eql? code}
              tcs.term_course.course.code = msts[0][:code]
              tcs.term_course.course.name = msts[0][:name]
            end

        end #if t.student.studies_plan_id.eql? 15
        #----------------------
=end
   my_final_classes.each_with_index do |mfc,index|
        ## SET CODE
        if @template_mode
          text = mfc[:code]
        else
          text= mfc[:code]
        end

        pdf.fill_color @text_color
        pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center
        ## SET COURSE NAME
        if @template_mode
          text = mfc[:name]
        else
          text = mfc[:name]
        end

        pdf.fill_color @text_color

        # Para hacer pruebas con el nombre mas largo que se encuentre en courses
        #text = "Medición y caracterización"  #26
        #text = "Medición y caracterización de recursos energéticos y" #52
        #text = "Medición y caracterización de recursos energéticos y evaluación económica de" #76
        #text = "Medición y caracterización de recursos energéticos y evaluación económica de proyectos" #86
        
        if text.size <=26
          y_1 = y
          h_1 = size_1 
        elsif text.size <= 52
          h_1 = (size_1 * 2) + 2
          y_1 = y + (h_1/4)
        elsif text.size <= 76
          h_1 = (size_1 * 3) + 2
          y_1 = y + (h_1/4)
        elsif text.size <= 100
          h_1 = (size_1 * 4) + 2
          y_1 = y + (h_1/4)
        end
        
        @rectangles = false
        if @rectangles then pdf.stroke_rectangle [x_1,y_1], w_1, h_1 end
        pdf.text_box text , :at=>[x_1,y_1], :width => w_1, :height=> h_1, :size=>size_1, :style=> :bold, :align=> :center, :valign=> :center

        ## SET TERM
        if @template_mode
          term = ""
        else
          term = mfc[:term_name]
        end
     
        year = term.at(2..3)
        subterm = term.at(5)

        if @template_mode
          text = ""
        else
          text = "#{year}/#{subterm}"
        end
        
        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x_2,y_2], w_2, h_2
        pdf.fill_color @text_color
        pdf.text_box text , :at=>[x_2,y_2], :width => w_2, :height=> h_2, :size=>size_2, :style=> :bold, :align=> :center, :valign=> :center

        ## SET GRADE
        if @template_mode
          text = ""
        else
          sum  = sum + mfc[:tcs_grade].to_f
          text = mfc[:tcs_grade].to_s
        end

        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x_3,y_3], w_3, h_3
        pdf.fill_color @text_color
        pdf.text_box text , :at=>[x_3,y_3], :width => w_3, :height=> h_3, :size=>size_3, :style=> :bold, :align=> :center, :valign=> :center

        ## SET GRADE ON TEXT
        if @template_mode
          text = ""
        else
          text = get_cardinal_name(mfc[:tcs_grade].to_i)
        end

        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x_4,y_4], w_4, h_4
        pdf.fill_color @text_color
        pdf.text_box text.capitalize, :at=>[x_4,y_4], :width => w_4, :height=> h_4, :size=>size_4, :style=> :bold, :align=> :center, :valign=> :center
        ## SET INTERLINE SPACE
        if tcss.size >= 14
          y = y - 33 + offset
          y_1 = y_1 - 33 + offset
          y_2 = y_2 - 33 + offset
          y_3 = y_3 - 33 + offset
          y_4 = y_4 - 33 + offset
        elsif tcss.size >= 11
          y = y - 33
          y_1 = y_1 - 33
          y_2 = y_2 - 33
          y_3 = y_3 - 33
          y_4 = y_4 - 33
        else
          y = y - 50
          y_1 = y_1 - 50
          y_2 = y_2 - 50
          y_3 = y_3 - 50
          y_4 = y_4 - 50
        end

        #text = "#{tcss.size}|#{index}"
        #pdf.text_box text , :at=>[x_4 + 80,y_4], :width => w_4, :height=> h_4, :size=>size_4, :style=> :bold, :align=> :center, :valign=> :center

        if ((tcss.size.in? [17,18]) && (index==5))
          pdf.start_new_page
          set_lines(pdf,648,235)
          #pdf.font "Arial"
          y   = 580
          y_1 = y + 14
          y_2 = y 
          y_3 = y
          y_4 = y + 6          
        elsif ((tcss.size.in? [14,15,16]) && (index==4))
          pdf.start_new_page
          set_lines(pdf,648,235)
          #pdf.font "Arial"
          y   = 575
          y_1 = y + 14
          y_2 = y 
          y_3 = y
          y_4 = y + 6 
        elsif ((tcss.size.in? [11,12,13]) && (index==3))
          pdf.start_new_page
          set_lines(pdf,648,235)
          #pdf.font "Arial"
          y   = 575
          y_1 = y + 12
          y_2 = y 
          y_3 = y
          y_4 = y + 6
        elsif ((tcss.size <= 10) && (index==2))
          pdf.start_new_page
          set_lines(pdf,648,235)
          #pdf.font "Arial"
          y   = 565
          y_1 = y + 10
          y_2 = y 
          y_3 = y
          y_4 = y + 6
        end
        counter = index
      end
 
      #pdf.font "Times"
      x    = 33
      y    = 202
      w    = 435
      h    = 20
      size = 10
      text =  "El presente certificado total ampara #{counter + 1} asignaturas. La escala de calificaciones es de 00 a 100  y la mínima aprobatoria es de 70."
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :justify, :valign=> :center, :character_spacing=>1.3
      #@rectangles = true
      #if @rectangles then pdf.stroke_rectangle [x,y], w, h end
      ## SET AVERAGE
      avg = (sum/(counter+1)).to_f
      y =  y - 18
      w = 200    
      h = 20
      text =  "Promedio General #{avg.round(2)}"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center, :character_spacing=>1
      ## SET DATE SITE
      y    =  y - 18
      w    =  250
      text =  "Chihuahua, Chih.,"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center, :character_spacing => 1.5
      ## SET DATETIME
      time = t.defence_date.to_time
      x = x + 96
      y = y - 4
      w = 250
      h = 9
      size  = 9
      day   = params[:day]
      month = params[:month]
      year  = params[:year] 
      if @template_mode
        text = "XX de XXXXXXX de XXXX"
      else
        text = "#{day} de #{get_month_name(month.to_i)} de #{year}"
      end

      pdf.text_box text , :at=>[x+45,y], :width => w, :height=> h, :size=>size, :align=> :left, :valign=> :center
      pdf.line_width   = 0.5
      pdf.stroke_line [x + 10, y - 10],[x + 176,y - 8.5]

      set_general_director_sign(pdf,16,71)
      set_academic_director_sign(pdf,250,71)
       
      if Rails.env.production?
       send_data pdf.render, type: "application/pdf", disposition: "attachment"
      else
       send_data pdf.render, type: "application/pdf", disposition: "inline"
      end
      
      return
    end
  end

  ####################################################################################################
  # SET LINES
  def set_lines(pdf,y1,y2)
    pdf.stroke_color= @text_color
    pdf.line_width= 0.5
    y_aux = 52
    y3 = y1 - y_aux
    y_offset = y1 - (y_aux / 2)
    # horizontal line (TOP)
    pdf.stroke_line [31.6,y1],[487.4,y1]
    # vertical lines
    pdf.stroke_line [31.7,y1],[31.7,y2]
    pdf.stroke_line [105.7,y1],[105.7,y2]
    pdf.stroke_line [215.3,y1],[215.3,y2]
    pdf.stroke_line [270.1,y1],[270.1,y2]
    pdf.stroke_line [316.3,y_offset],[316.3,y2]
    pdf.stroke_line [399.4,y1],[399.4,y2]
    pdf.stroke_line [487.2,y1],[487.2,y2]
    # horizontal line 0 (MIDDLE)
    pdf.stroke_line [270,y_offset],[399.3,y_offset]
    # horizontal line 1 (BOTTOM TITLES)
    pdf.stroke_line [31.6,y3],[487.4,y3]
    # horizontal line 2 (BOTTOM DOCUMENT)
    #pdf.stroke_line [34.6,y2],[487.4,y2]
    pdf.stroke_line [31.5,y2],[487.4,y2]

    #set titles
    pdf.font "Times"
    @size = 11
    pdf.text_box "Clave", :at=>[24,y1 + 7], :width => 90, :height=> 60, :size=>@size, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "Nombre de la asignatura", :at=>[114, y1 + 5], :width => 90, :height=> 60, :size=>@size, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "Ciclo", :at=>[215, y1-2], :width => 55, :height=> 49, :size=>@size, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "Calificación", :at=>[289, y1 + 1], :width => 90, :height=> 30, :size=>@size, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "Número", :at=>[270.5, y1 - 28], :width => 45, :height=> 20, :size=>@size, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "Letra", :at=>[334, y1 - 28], :width => 45, :height=> 20, :size=>@size, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "Observaciones", :at=>[399, y1 - 2], :width => 90, :height=> 50, :size=>@size, :align=> :center, :valign=> :center, :style=>:bold
  end

  ####################################################################################################
  # SET GENERAL DIRECTOR SIGN
  def set_general_director_sign(pdf,x,y)
    ## SET LINE
    pdf.stroke_color= @text_color
    pdf.line_width= 0.5
    pdf.stroke_line [x + 32,y + 10],[232,y + 10]
    ## SET GENERAL DIRECTOR NAME
    w = 250
    h = 14
    size = 12
    # Load locale config
    dir = t(:directory)
    title = dir[:general_director][:title].mb_chars
    name = dir[:general_director][:name].mb_chars
    job  = dir[:general_director][:job]
    text = "#{title} #{name}"
    pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
    # SET APPOINTMENT
    x = x
    y = y - 14
    w = 250
    h = 14
    size = 12
    text = "#{job}"
    pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
  end

  ####################################################################################################
  # SET ACADEMIC DIRECTOR SIGN
  def set_academic_director_sign(pdf,x,y)
    ## SET LINE
    pdf.stroke_color= @text_color
    pdf.line_width= 0.5
    pdf.stroke_line [x + 32,y + 10],[462,y + 10]
    ## SET NAME
    w = 250
    h = 14
    size = 12
    # Load locale config
    dir = t(:directory)
    title = dir[:academic_director][:title].mb_chars
    name = dir[:academic_director][:name].mb_chars
    job  = dir[:academic_director][:job]
    text = "#{title} #{name}"
    pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
    # SET APPOINTMENT
    x = x
    y = y - 14
    w = 250
    h = 14
    size = 12
    text = "#{job}"
    pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :center, :valign=> :center
  end
end
