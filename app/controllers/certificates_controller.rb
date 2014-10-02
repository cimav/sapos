# coding: utf-8
class CertificatesController < ApplicationController
  load_and_authorize_resource
  before_filter :auth_required
  respond_to :html, :xml, :json

  def total_studies_certificate
    @r_root    = Rails.root.to_s
    t = Thesis.find(params[:thesis_id])
    libro = params[:libro]
    foja  = params[:foja]
    dir = t(:directory)
    filename = "#{@r_root}/private/prawn_templates/certificado_estudios_totales_blank.pdf"
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
     
      set_decor_lines(pdf)
      
      ## SET CENTER IMAGE
      image = "#{Rails.root}/private/images/logo_cimav_100.png" 
      y = 690
      pdf.image image, :at => [22,y], :height => 42
      ## SET CENTER TITLE
      x = 93
      w = 360 
      h = 50
      pdf.stroke_color= "000000"
      pdf.line_width= 0.2 
      pdf.bounding_box([x,y],:width=>w, :height=>h,:kerning=>true) do
        pdf.text dir[:center].mb_chars.upcase, :align=>:center, :style=>:bold, :size=>20, :character_spacing=>-0.6
      end 
 
      ## SET FOLIO TITLE, LINE AND FOLIO
      # SET FOLIO TITLE
      x = 349
      y = y - 72
      w = 100
      h =  11
      size = 10
      text = "CERTIFICADO No."
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left
      ## SET FOLIO LINE
      y = y - 8
      pdf.stroke_color= "373435"
      pdf.line_width= 0.2 
      pdf.stroke_line [x + 88,y],[485,y]
      ## SET FOLIO 
      x = 440
      y = y + 8
      w = 40
      h = 10
      text = "#{libro}-#{foja}"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :center

      ## SET NAME AND PROGRAM NAME
      # SET NAME
      x = 46
      y = y - 54
      w = 550
      h = 13
      size = 12
      text = "HACE CONSTAR QUE #{t.student.full_name.mb_chars.upcase}"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center
      # SET PROGRAM NAME
      y = y - 14
      w = 400
      h = 26
      size = 12
      text = "CURSÓ Y ACREDITÓ: #{t.student.program.name.mb_chars.upcase}"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center

      # SET ROLLOTE
      pdf.stroke_color= "000000"
      x = 164
      y = y - 76
      w = 320
      h = 80
      size = 12
      
      l = 4
      pdf.bounding_box([x,y],:width=>w + 20, :height=>h + 33,:kerning=>true) do
        pdf.text "CONFORME  A  LOS  PLANES  DE  ESTUDIO  VIGENTES", :style=>:bold, :align=>:justify,:leading=>l,:character_spacing=>0.4 
        pdf.text "CONSERVANDOSE LAS EVALUACIONES", :style=>:bold, :align=>:justify,:leading=>l,:character_spacing=>3.63132
        pdf.text "DE LA TOTALIDAD DE LOS PROGRAMAS", :style=>:bold, :align=>:justify,:leading=>l,:character_spacing=>3.153
        pdf.text "V       I       G       E       N       T       E       S", :style=>:bold, :align=>:justify,:leading=>l,:character_spacing=>2.281
        pdf.text "EN LOS ARCHIVOS DE ESTA INSTITUCIÓN", :style=>:bold, :align=>:justify,:leading=>l,:character_spacing=>2.633
      end 
     
      # SET PHOTO
      pdf.line_width = 0.8
      y = y + 3
      x = 41
      w = 70
      h = 75
      pdf.stroke_rectangle [x,y],w,h
      pdf.text_box "Fotografía del Alumno Tamaño Infantil", :at=>[x + 2,y - 2], :width => w - 3, :height=> h - 5, :size=>6, :style=> :bold, :align=> :center, :valign=> :center

      ## STUDENT SIGN
      x    = 30
      y    = y - 108
      x1   = 128
      pdf.stroke_line [x,y],[x1,y]
      x    = x + 6
      y    = y - 7
      w    = 100
      h    = 10
      size = 8
      text = "FIRMA DEL ALUMNO"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left

      ## SET SUBTITLE
      x    = 109
      y    = y - 41
      w    = 300
      h    = 16
      size = 15
      text = "CERTIFICADO DE ESTUDIOS TOTALES"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :center
       
      set_lines(pdf,y - 33, 50)
    
      if t.student.program.level.to_i.eql? 2
        tcss = TermCourseStudent.joins(:term_student).joins(:term_course=>:course).where("term_students.student_id=? AND term_course_students.status=? AND term_course_students.grade>=? AND courses.program_id=?",t.student.id,TermCourseStudent::ACTIVE,70,t.student.program_id).order(:code)
      else
        tcss = TermCourseStudent.joins(:term_student).joins(:term_course=>:course).where("term_students.student_id=? AND term_course_students.status=? AND term_course_students.grade>=?",t.student.id,TermCourseStudent::ACTIVE,70).order(:code)
      end

      pdf.font "Arial"
      if tcss.size > 11
        # CODE INITIAL DATA
        x = 63
        y = 210 
        w = 20 
        h = 9
        size = 6 
        # COURSE NAME INITIAL DATA
        x_1 = 107
        y_1 = y + 8
        w_1 = 106
        h_1 = 25
        size_1 = 6
        # TERMS INITIAL DATA
        x_2 = 220
        y_2 = y + 1
        w_2 = 45
        h_2 = 9
        size_2 = 5
        # GRADE INITIAL DATA
        x_3 = 273
        y_3 = y
        w_3 = 38
        h_3 = 9
        size_3 = 6
        # GRADE ON TEXT INITIAL DATA
        x_4 = 317
        y_4 = y + 5
        w_4 = 82
        h_4 = 20
        size_4 = 6
      else
        # CODE INITIAL DATA
        x = 60
        y = 205
        w = 20 
        h = 9
        size = 8 
        # COURSE NAME INITIAL DATA
        x_1 = 108
        y_1 = y + 6
        w_1 = 106
        h_1 = 25
        size_1 = 8
        # TERMS INITIAL DATA
        x_2 = 220
        y_2 = y + 1
        w_2 = 45
        h_2 = 9
        size_2 = 7
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
        h_4 = 18
        size_4 = 8
        # GENERAL DATA
        text = ""
      end
      
      counter = 0
      tcss.each_with_index do |tcs,index|
        ## SET CODE
        text= tcs.term_course.course.code

        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x,y], w, h
        pdf.fill_color "000000"
        pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center
        ## SET COURSE NAME
        text= tcs.term_course.course.name.mb_chars.upcase
        
        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x_1,y_1], w_1, h_1
        pdf.fill_color "000000"

        if tcs.term_course.course.name.size > 52
          y_1 = y_1 + 10
          h_1 = h_1 + 20
        elsif  tcs.term_course.course.name.size > 36
          y_1 = y_1 + 5 
          h_1 = h_1 + 10
        end

        pdf.text_box text , :at=>[x_1,y_1], :width => w_1, :height=> h_1, :size=>size_1, :style=> :bold, :align=> :center, :valign=> :center
        
        ## SET TERM
        term = tcs.term_course.term.name
        year = term.at(2..3)
        subterm = term.at(5)

        text = "#{year}/#{subterm}"
        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x_2,y_2], w_2, h_2
        pdf.fill_color "000000"
        pdf.text_box text , :at=>[x_2,y_2], :width => w_2, :height=> h_2, :size=>size_2, :style=> :bold, :align=> :center, :valign=> :center

        ## SET GRADE
        text = tcs.grade.to_s
        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x_3,y_3], w_3, h_3
        pdf.fill_color "000000"
        pdf.text_box text , :at=>[x_3,y_3], :width => w_3, :height=> h_3, :size=>size_3, :style=> :bold, :align=> :center, :valign=> :center
          
        ## SET GRADE ON TEXT
        text = get_cardinal_name(tcs.grade.to_i)
        pdf.fill_color "ffffff"
        pdf.fill_rectangle [x_4,y_4], w_4, h_4
        pdf.fill_color "000000"
        pdf.text_box text.upcase , :at=>[x_4,y_4], :width => w_4, :height=> h_4, :size=>size_4, :style=> :bold, :align=> :center, :valign=> :center
        ## SET INTERLINE SPACE
        if tcss.size > 11
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

        if ((tcss.size > 10) && (index==4))
          pdf.start_new_page
          set_decor_lines(pdf)
          set_lines(pdf,648,235)
          pdf.font "Arial"
          y   = 575
          y_1 = y + 12
          y_2 = y + 1
          y_3 = y
          y_4 = y + 5
        elsif ((tcss.size <= 10) && (index==2))
          pdf.start_new_page
          set_decor_lines(pdf)
          set_lines(pdf,648,235)
          pdf.font "Arial"
          y   = 565
          y_1 = y + 6
          y_2 = y + 1
          y_3 = y 
          y_4 = y + 5
        end
        counter = index
      end
    
      pdf.font "Times"
      x    = 51
      y    = 172
      w    = 500
      h    = 20
      size = 9
      text =  "EL PRESENTE CERTIFICADO TOTAL AMPARA #{counter + 1} ASIGNATURAS. LA ESCALA DE CALIFICACIONES\n ES DE 00 A 100 Y LA MINIMA APROBATORIA ES DE 70."
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center
      ## SET DATE SITE
      y    =  y - 18
      w    =  250
      h    =  20
      text =  "CHIHUAHUA, CHIH.,"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :style=> :bold, :align=> :left, :valign=> :center
      ## SET DATETIME
      time = Time.new
      x = x + 96
      y = y - 4 
      w = 250
      h = 9
      size = 9
      text = "a #{time.day.to_s} de #{get_month_name(time.month)} de #{time.year.to_s}"
      pdf.text_box text , :at=>[x,y], :width => w, :height=> h, :size=>size, :align=> :left, :valign=> :center
      pdf.line_width   = 0.5
      pdf.stroke_line [x - 2, y - 8.5],[x + 176,y - 8.5]
     
      set_general_director_sign(pdf,16,71)
      set_posgrado_chief_sign(pdf,250,71)
      send_data pdf.render, type: "application/pdf", disposition: "inline"
      return
    end
  end

  ####################################################################################################
  # SET LINES
  def set_lines(pdf,y1,y2)
    pdf.stroke_color= "000000"
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
    pdf.stroke_line [34.6,y2],[487.4,y2]

    #set titles
    pdf.font "Times"
    pdf.text_box "CLAVE", :at=>[24,y1 + 7], :width => 90, :height=> 60, :size=>11, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "NOMBRE DE LA ASIGNATURA", :at=>[119, y1 + 8], :width => 90, :height=> 60, :size=>10, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "CICLO EN QUE SE CURSÓ", :at=>[215, y1 + 4], :width => 55, :height=> 49, :size=>10, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "CALIFICACIÓN", :at=>[288, y1 + 1], :width => 90, :height=> 30, :size=>9, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "NÚMERO", :at=>[270.5, y1 - 25], :width => 45, :height=> 20, :size=>8, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "LETRA", :at=>[334, y1 - 26], :width => 45, :height=> 20, :size=>9, :align=> :center, :valign=> :center, :style=>:bold
    pdf.text_box "OBSERVACIONES", :at=>[399, y1 - 1], :width => 90, :height=> 50, :size=>9, :align=> :center, :valign=> :center, :style=>:bold
  end

  ####################################################################################################
  # SET DECOR LINES
  def set_decor_lines(pdf)
      ## LINES
      y_top    = 720
      y_bottom = 15
      
      x_right  = 1
      x_left   = 508 

      y        = y_top
      pdf.stroke_color = "ff0000"
      pdf.line_width   = 4
      pdf.stroke_line [x_right,y],[x_left,y]
      x = 3
      y = y - 16
      pdf.stroke_color = "52658C"
      pdf.line_width   = 4 
      pdf.stroke_line [x_right,y],[x_left,y]
      
      y        = y_bottom
      pdf.stroke_color = "52658C"
      pdf.line_width   = 4 
      pdf.stroke_line [x_right,y],[x_left,y]
      x = 3
      y = y - 16
      pdf.stroke_color = "ff0000"
      pdf.line_width   = 4
      pdf.stroke_line [x_right,y],[x_left,y]
  end

  ####################################################################################################
  # SET GENERAL DIRECTOR SIGN
  def set_general_director_sign(pdf,x,y)
    ## SET LINE
    pdf.stroke_color= "373435"
    pdf.line_width= 0.5
    pdf.stroke_line [x + 32,y + 10],[232,y + 10]
    ## SET GENERAL DIRECTOR NAME
    w = 250
    h = 14
    size = 12
    # Load locale config
    dir = t(:directory)
    title = dir[:general_director][:title].mb_chars.upcase 
    name = dir[:general_director][:name].mb_chars.upcase
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
  # SET POSGRADO CHIEF SIGN
  def set_posgrado_chief_sign(pdf,x,y)
    ## SET LINE
    pdf.stroke_color= "373435"
    pdf.line_width= 0.5
    pdf.stroke_line [x + 32,y + 10],[462,y + 10]
    ## SET NAME
    w = 250
    h = 14
    size = 12
    # Load locale config
    dir = t(:directory)
    title = dir[:posgrado_chief][:title].mb_chars.upcase 
    name = dir[:posgrado_chief][:name].mb_chars.upcase
    job  = dir[:posgrado_chief][:job]
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
