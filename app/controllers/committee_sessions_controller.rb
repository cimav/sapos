# coding: utf-8
class CommitteeSessionsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
  end

  def live_search
    @c_sessions = CommitteeSession.where(:status=>[1,2,3]).order('date DESC')
    if !params[:q].blank?
      if params[:q].to_i != 0
        @c_sessions = @c_sessions.where("id = ?",params[:q].to_i)
      end
    end
    render :layout => false
  end

  def new
    @committee_session = CommitteeSession.new
    @staffs = Staff.where(:status=>0,:institution_id=>1)

    render :layout => false
  end

  def create
    flash = {}
    parameters = {}
    @c_session        = CommitteeSession.new()
    @c_session.status         = 1
    @c_session.session_type   = params[:committee_session][:session_type]
    @c_session.date           = get_datetime(params)

    if @c_session.save
       att = params[:hidden_attendees].split(",")
       att.each do |a|
         @csa                      = CommitteeSessionAttendee.new()
         @csa.committee_session_id = @c_session.id
         @csa.staff_id             = a
         @csa.save
       end

      render_message(@c_session,"Alta de sesión exitosa",parameters)
    else
      render_error(@c_session,"Error al dar de alta la sesión",parameters)
    end
  end

  def update
    parameters = {}
    @committee_session = CommitteeSession.find(params[:id])
    @committee_session.status = 3
    @committee_session.end_session    = get_end_datetime(params)
    if @committee_session.save
      @message = "Sesion finalizada"
      render_message @committee_session,@message,parameters
    else
      render_error @committee_session, "Error al finalizar la sesion",parameters
    end
  end


  def get_end_datetime(params)
    date    = params[:committee_session][:date]
    hour    = params[:end_session_hour]
    minutes = params[:end_session_minutes]
    return "#{date} #{hour}:#{minutes}:00"
  end
  
  def get_datetime(params)
    date    = params[:committee_session][:date]
    hour    = params[:session_hour]
    minutes = params[:session_minutes]
    return "#{date} #{hour}:#{minutes}:00"
  end

  def show
    @c_session       = CommitteeSession.find(params[:id])
    @attendees       = CommitteeSessionAttendee.where(:committee_session_id=>params[:id])
    @staffs          = Staff.where(:status=>0,:institution_id=>1)
    @agreement_types = CommitteeAgreementType.all

    my_date          = @c_session.date.to_s()
    @c_session.date  = my_date.split(" ")[0]
    @hour            = my_date.split(" ")[1].split(":")[0] rescue ""
    @minutes         = my_date.split(" ")[1].split(":")[1] rescue ""
    
    my_date                 = @c_session.end_session.to_s()
    #@c_session.end_session  = my_date.split(" ")[0]
    @ehour            = my_date.split(" ")[1].split(":")[0] rescue ""
    @eminutes         = my_date.split(" ")[1].split(":")[1] rescue ""
    render :layout => false
  end

  def agreements
    @a_id      = params[:a_id]
    @s_id      = params[:s_id]
    @page      = params[:page]
    @operation = params[:operation]

    @committee_agreements = []
    @committee_session = CommitteeSession.find(@s_id)

    if @a_id.eql? "todos"
      @size = @committee_agreements = CommitteeAgreement.where(:committee_session_id=>@s_id).size

      if @size <= 12
        @committee_agreements = CommitteeAgreement.where(:committee_session_id=>@s_id).to_a
      else
        @pages = @size/10

        if (@size%10)>=1  #si es 1 u otro número es la página correcta mas 1
          @pages = @pages + 1
        end

        if @operation.eql? "add" #devuelve la última página
          @page = @pages
        elsif @operation.eql? "sub" #devuelve la página actual o ...
          if (@size%10).eql? 0 #si es entero el total de paginas es incorrecto 
            @page  = @pages
          end
        end

        begining  = (@page.to_i-1) * 10
        registers = 10

        limit = "#{begining},#{registers}"

        @committee_agreements = CommitteeAgreement.where(:committee_session_id=>@s_id).limit(limit).to_a 
      end
    else

  
      ## NUEVO INGRESO
      @committee_agreement = CommitteeAgreement.new

      @committee_agreement.committee_agreement_type_id= @a_id
      @committee_agreement.committee_session_id= @s_id
      @committee_agreement.save

      @committee_agreements << @committee_agreement

    end
    render :layout => false
  end

  def delete_agreement
    CommitteeAgreement.find(params[:a_id]).destroy
    render :layout => false
  end

  def delete_person
    CommitteeAgreementPerson.find(params[:s_id]).delete
    render :layout => false
  end

  def save_text_agreement
    @a_id= params[:a_id]
    @can = CommitteeAgreementNote.where(:committee_agreement_id=>@a_id)[0]
    if !@can.nil?
      @can.notes = params[:text]
      @can.save
    else
      @can = CommitteeAgreementNote.new
      @can.committee_agreement_id = @a_id
      @can.notes = params[:text]
      @can.save
    end
    render :layout => false
  end

  def add_person
    @a_id        = params[:a_id]
    @p_id        = params[:id]
    @person_type = params[:person]
    @agreement = CommitteeAgreement.find(@a_id)
    @aux         = nil


    json       = {}
    @action    = "new"
    @estatus   = 1
    json[:estatus]   = 1
    json[:person_id] = 0

    #No se permiten multiples destinatarios en ASUNTOS GENERALES
    if @agreement.committee_agreement_type_id == 20
      CommitteeAgreementPerson.where(:committee_agreement_id=>@a_id).destroy_all
    end

    if @person_type.eql? "aspirante"
      @cap = CommitteeAgreementPerson.where(:committee_agreement_id=>@a_id,:attachable_type=>"Applicant")
      if @cap.size>0
        @action = "update"
      end
      @person = Applicant.find(@p_id)
      @cap = @cap[0]
    elsif @person_type.eql? "estudiante"
      @cap = CommitteeAgreementPerson.where(:committee_agreement_id=>@a_id,:attachable_type=>"Student")
      if @cap.size>0
        @action = "update"
      end
      @person = Student.find(@p_id)
      @cap = @cap[0]
    elsif @person_type.eql? "internado"
      @cap = CommitteeAgreementPerson.where(:committee_agreement_id=>@a_id,:attachable_type=>"Internship")
      if @cap.size>0
        @action = "update"
      end
      @person = Internship.find(@p_id)
      @cap = @cap[0]
    elsif @person_type.eql? "docente"
      @cap = CommitteeAgreementPerson.where(:committee_agreement_id=>@a_id,:attachable_type=>"Staff")
      if @cap.size>0
        @action = "update"
      end
      @person = Staff.find(@p_id)
      @cap = @cap[0]
    elsif @person_type.eql? "sinodales"
      @cap = CommitteeAgreementPerson.where(:committee_agreement_id=>@a_id,:attachable_type=>"Staff")
      @aux = params[:aux]
      if @cap.size>10
      #if @cap.size>4
       ## mas de 5 sinodales
        @estatus = 4
        json[:estatus] = 4
        @action = "no"
      else
        @cap = CommitteeAgreementPerson.where(:committee_agreement_id=>@a_id,:attachable_id=>@p_id,:attachable_type=>"Staff")
        if @cap.size>0
          ## la persona se repite
          @estatus = 2
          json[:estatus] = 2
          @action = "no"
        else
          @action = "new"
          @person = Staff.find(@p_id)
        end
      end
    end


    if @action.eql? "no"
      @x = ""  ## esta linea solo esta para evitar el fallo cuando el if esta vacio x no se vuelve a usar
    else
      if @action.eql? "new"
        @cap =  CommitteeAgreementPerson.new
        @cap.committee_agreement_id = @a_id
        @cap.aux = @aux
      end
        @cap.attachable_id   = @person.id
        @cap.attachable_type = @person.class.to_s
        @cap.save
        @person_id           = @cap.id
        json[:person_id]     = @cap.id
    end

    #render :layout => false
    render :json => json
  end

  def add_auth
    @a_id        = params[:a_id]
    @p_id        = params[:id]

    @ca = CommitteeAgreement.find(@a_id)
    @ca.auth = @p_id
    @ca.save
    render :layout => false
  end

  def add_note
    @a_id        = params[:a_id]
    @note        = params[:note]

    @ca = CommitteeAgreement.find(@a_id)
    @ca.notes = "[#{@note}]"
    @ca.save
    render :layout => false
  end

  def get_courses
    @term         = params[:term]
    @term_program = Term.find(@term).program_id rescue nil
    @courses = Course.select("id,name").where(:status=>1)
    @courses = Course.joins(:program).select("courses.id,courses.name,programs.prefix").where(:status=>1)

    json = {}
    json[:courses] = @courses
    render :json => json
  end

  def get_revalidation_courses
    @include_js   = "committee_sessions.reval.js"
    @committee_agreement = CommitteeAgreement.find(params[:id])
    @committee_agreement_courses = CommitteeAgreementObject.where(:committee_agreement_id=>params[:id],:attachable_type=>"Course")
    render :layout => 'standalone'
  end

  def roll_attendee
    @csa = CommitteeSessionAttendee.find(params[:id])
    @csa.checked = params[:checked]
    @csa.save
    render :layout => false
  end

  def add_attendee
    @csa                      = CommitteeSessionAttendee.new()
    @csa.committee_session_id = params[:cs_id]
    @csa.staff_id             = params[:st_id]
    @csa.save

    render :layout => false
  end

  def delete_attendee
    CommitteeSessionAttendee.find(params[:csa_id]).delete
    return :layout=> false
  end

  def unlock
    parameters = {}
    pwd = "p0p0p2"

    @c_session = CommitteeSession.find(params[:id])

    if pwd.eql? params[:pwd]
      @c_session.status = 1
      if @c_session.save
        render_message(@c_session,"Desbloqueo exitoso",parameters);
      else
        render_error(@c_session,"Error al cambiar el estatus",parameters);
      end
    else
      render_error(@c_session,"Password erroneo",parameters);
    end
  end

  def document_agreement
    @r_root = Rails.root.to_s

    @s_id = params[:s_id]  ## signer_id
    @c_a  = CommitteeAgreement.find(params[:a_id])  ## committee_agreement
    @c_s  = @c_a.committee_session                  ## committee_agreement_session
    @type = @c_a.committee_agreement_type.id

    if @s_id.to_i.eql? 1
      @signer = "Lic. Emilio Pascual Domínguez Lechuga\nCoordinador de Estudios de Posgrado"
      @sign   = "#{Rails.root.to_s}/private/images/firmas/firma1.png"
      @x_sign = 130
      @y_sign = 20
      @w_sign = 55
    elsif @s_id.to_i.eql? 2
      @signer = "Dr. Roberto Martínez Sánchez\n"
      @sign   = "#{Rails.root.to_s}/private/images/firmas/firma2.png"
      @x_sign = 110
      @y_sign = 0
      @w_sign = 100
    elsif @s_id.to_i.eql? 3
      @signer = "Dr. Erasmo Orrantia Borunda\n"
      @sign   = "#{Rails.root.to_s}/private/images/firmas/firma3.png"
      @x_sign = 75
      @y_sign = -15
      @w_sign = 155
    else
      @signer = "Sin firma definida\n"
      @sign   = "#{Rails.root.to_s}/private/images/firmas/blank.png"
      @x_sign = 130
      @y_sign = 20
      @w_sign = 55
    end
    @render_pdf = false
    @rectangles = false
    @nbsp = Prawn::Text::NBSP

    filename = "#{Rails.root.to_s}/private/prawn_templates/membretada.png"
    Prawn::Document.new(:background => filename, :background_scale=>0.36, :margin=>60 ) do |pdf|
      if !(@type.in? 6,21)
        ############# CABECERA
        x = 250
        y = 590 #657
        w = 260
        h = 43
        size = 10
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        s_date           = @c_s.date
        last_change      = @c_s.updated_at
        today            = Date.today
        @session_type    = @c_s.get_type

        pdf.text_box "<b>Coordinación de Posgrado</b>\n<b>A#{@c_a.get_agreement_number}.#{last_change.month}<sup>#{@c_s.folio_sup}</sup>.#{last_change.year}</b>\nChihuahua, Chih., a #{s_date.day} de #{get_month_name(s_date.month)} de #{s_date.year}", :inline_format=>true, :at=>[x,y], :align=>:right,:valign=>:center, :width=>w, :height=>h, size: size
      end
  
      ## corpo segun tipo
      ############################### NUEVO INGRESO ###################################
      if @type.eql? 1
        @render_pdf = true
        x = 0
        y = 500
      ############################### PERMANENCIA ###################################
      elsif @type.eql? 2
        @render_pdf = true
        # PRESENTE
        x = 0
        y = 555
        w = 300
        h = 15
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        s     = @c_a.committee_agreement_person.where(:attachable_type=>"Student")
        notes = @c_a.committee_agreement_note[0].notes rescue ""
        l_date     = Date.parse(@c_a.notes[/\[(.*?)\]/m,1]) rescue ""
        student    = Student.find(s[0].attachable_id)
        supervisor = Staff.find(student.supervisor)

        if @c_a.auth.to_i.eql? 1 ####### Si
          ############ PRORROGA ############
          pdf.text_box "</b>C. #{student.full_name}</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true
          y = y - 15
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
          # CONTENIDO
          y = y - 60
          w = 510
          h = 180
          texto = " #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp}Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado le ha autorizado una prórroga para presentar sus requisitos de titulación ante este comité a mas tardar el #{l_date.day} de #{get_month_name(l_date.month)} de #{l_date.year}."

          if notes.blank?
            texto = "#{texto}\n\n"
          else
            texto = "#{texto}\n\n#{notes}\n\n"
          end

          texto = "#{texto}Es importante señalar que de no cumplir con los compromisos en las fechas indicadas, sera dado de baja del programa al que pertenece."
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box texto, :at=>[x,y], :align=>:justify, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
          #  FIRMA
          x = x + 90
          y = y - 200
          w = 300
          h = 80
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
          pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
          pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
        elsif @c_a.auth.to_i.eql? 2 ####### No
          ############ CONSTANCIA DE BAJA ############
          pdf.text_box "</b>C. #{student.full_name}</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true
          y = y - 15
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
          # CONTENIDO
          y = y - 60
          w = 510
          h = 80
          texto = " #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp}Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado ha determinado su baja definitiva por incumplimiento del Programa de #{student.program.name}, con base en el artículo 30 del Reglamento de Estudios de Posgrado vigente que establece que el estudiante podrá ser dado de baja por:\n\n"
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box texto, :at=>[x,y], :align=>:justify, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
          #  OPCIONES
          x = x + 70
          y = y - 90
          w = 400
          h = 60
          texto = "a) No presentar la propuesta de titulación en los plazos establecidos\nb) Exceder el tiempo de permanencia en el Programa"
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box texto, :at=>[x,y], :align=>:left, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
          #  FIRMA
          x = x + 20
          y = y - 70
          w = 300
          h = 80
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
          pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
          pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
          # CCP
          x = 0
          y = y - 150
          w = 350
          h = 25
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          texto = "c.c.p #{supervisor.title}. #{supervisor.full_name} - Director de Tesis.\n #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp}Expediente."
          pdf.text_box texto, :at=>[x,y], :align=>:left, :valign=>:top, :width=>w, :height=>h, :inline_format=>true, :size=>10
        elsif @c_a.auth.to_i.eql? 3 
          ############ RENUNCIA EXPLICITA #############
          pdf.text_box "</b>C. #{student.full_name}</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true
          y = y - 15
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
          # CONTENIDO
          y = y - 60
          w = 510
          h = 180
          texto = " #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp}Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado ha determinado su baja definitiva al programa de posgrado al que se encuentra adscrito por renuncia explícita."
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box texto, :at=>[x,y], :align=>:justify, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
          #  FIRMA
          x = x + 100
          y = y - 130
          w = 300
          h = 80
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
          pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
          pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
          # CCP
          x = 0
          y = y - 150
          w = 350
          h = 25
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          texto = "c.c.p #{supervisor.title}. #{supervisor.full_name} - Director de Tesis.\n #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp}Expediente."
          pdf.text_box texto, :at=>[x,y], :align=>:left, :valign=>:top, :width=>w, :height=>h, :inline_format=>true, :size=>10
      end
      ############################### CAMBIO DE PROGRAMA ###################################
      elsif @type.eql? 3
        #@rectangles  = true
        x = 0
        y = 555
        w = 300
        h = 15
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        @render_pdf  = true
        s       = @c_a.committee_agreement_person.where(:attachable_type=>"Student")
        student = Student.find(s[0].attachable_id)
        program = Program.find(@c_a.auth)
        ## PRESENTACION
        pdf.text_box "</b>C. #{student.full_name}</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true
        y = y - 15
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
        # CONTENIDO
        y = y - 60
        w = 510
        h = 80
        texto = " #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp}Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado le ha autorizado el cambio de programa de #{student.program.name} al de #{program.name},\n\n Por lo anterior, deberá cumplir con la carga académica de acuerdo al plan de estudios aplicable en el Programa de posgrado que fue autorizado.\n\n Me encuentro a sus ordenes cualquier duda al respecto\n\n"
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box texto, :at=>[x,y], :align=>:justify, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
        # FIRMA
        x = x + 90
        y = y - 80
        w = 300
        h = 80
        texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
        pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
        pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
      ############################### CAMBIO DE DIRECTOR DE TESIS ###################################
      elsif @type.eql? 4
        #@rectangles  = true
        @render_pdf  = true
        s              = @c_a.committee_agreement_person.where(:attachable_type=>"Student")
        tutor          = @c_a.committee_agreement_person.where(:attachable_type=>"Staff")
        student        = Student.find(s[0].attachable_id)
        supervisor     = Staff.find(student.supervisor)
        new_supervisor = Staff.find(tutor[0].attachable_id)
        # PRESENTE
        x = 0
        y = 550
        w = 300
        h = 15
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box "</b>#{new_supervisor.title} #{new_supervisor.full_name_cap}</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true, size: size
        y = y - 15
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
        # CONTENIDO
        y = y - 35
        w = 510
        h = 100
        texto = " #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp}Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado lo ha nombrado como director de tesis de #{student.full_name} del Programa de #{student.program.name}.\n\n A continuación le informo los avances que deberá tener el estudiante durante su trayectoria académica: \n\n"
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box texto, :at=>[x,y], :align=>:justify, :valign=>:top, :width=>w, :height=>h, :inline_format=>true, size: size
        pdf.move_down 235
        data = []
        if student.program.level.to_i.eql? 2
          data << ["Semestre 1","Protocolo de Investigación"]
          data << ["Semestre 2","Porcentaje de cumplimiento de las actividades de investigación indicadas por su Comité Tutoral en la evaluación semestral previa y discusión de los resultados del avance de su investigación"]
          data << ["Semestre 3","Porcentaje de cumplimiento de las actividades de investigación indicadas por su Comité Tutoral en la evaluación semestral previa y discusión de los resultados del avance de su investigación"]
          data << ["Semestre 4","Porcentaje de cumplimiento de las actividades de investigación indicadas por su Comité Tutoral en la evaluación semestral previa, discusión de los resultados del avance de investigación"]
          data << ["Semestre 5","Porcentaje de cumplimiento de las actividades de investigación indicadas por su Comité Tutoral en la evaluación semestral previa, discusión de los resultados del avance de investigación"]
          data << ["Semestre 6","Porcentaje de cumplimiento de las actividades de investigación indicadas por su Comité Tutoral en la evaluación semestral previa, envío del artículo y discusión de los resultados del desarrollo experimental"]
          data << ["Semestre 7","Primer borrador de la tesis y seguimiento al envío del artículo"]
          data << ["Semestre 8","Seminario departamental final"]
        else
          data << ["Semestre 2","Protocolo de Investigación"]
          data << ["Semestre 3","Resultados del desarrollo experimental"]
          data << ["Semestre 4","Seminario departamental final"]
        end

        tabla = pdf.make_table(data,:width=>492,:cell_style=>{:size=>9,:padding=>3,:inline_format => true},:position=>:center,:column_widths=>{1 => 410}) #solo s especifica la columna 2
        tabla.draw
        pdf.move_down 20
        texto= "Me encuentro a sus ordenes para cualquier duda al respecto. \n"
        pdf.text texto, :align=>:justify, :valign=>:top, :inline_format=>true, size: size
        #  FIRMA
        x = x + 100
        y = y - h - 0
        w = 300
        h = 80
        pdf.move_down 50
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        texto = "Atentamente,\n\n\n\n\n<b>#{@signer}</b>"
        pdf.text_box texto, :at=>[x,y-230], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true, size: size

        # CCP
        x = 0
        y = 50
        w = 350
        h = 25
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        texto = "c.c.p #{student.full_name}\n #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp} #{@nbsp}Expediente."
        pdf.text_box texto, :at=>[x,y], :align=>:left, :valign=>:top, :width=>w, :height=>h, :inline_format=>true, size: size
      ############################### DESIGNACION DE SINODALES ###################################
      elsif @type.eql? 5
        @render_pdf  = true
        s            = @c_a.committee_agreement_person.where(:attachable_type=>"Student")
        tutors       = @c_a.committee_agreement_person.where(:attachable_type=>"Staff",:aux=>1)
        student      = Student.find(s[0].attachable_id)
        supervisor   = Staff.find(student.supervisor)
        comma_tutors = ""
        tutors.each do |t|
          tutor = Staff.find(t.attachable_id)
          comma_tutors = "#{comma_tutors}#{tutor.title} #{tutor.full_name_cap}, "
        end
        # PRESENTE
        x = 0
        y = 505
        w = 480
        h = 15
        if comma_tutors.chop.chop.size > 85
          h = 30
        end
        if comma_tutors.chop.chop.size > 170
          h = 45
        end
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box "</b>#{comma_tutors.chop.chop}</b>", :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
        y = y - h
        w = 200
        h = 15
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
        # CONTENIDO
        x = 0
        y = y - 60
        w = 510
        h = 100
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box "Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado lo ha nombrado sinodal de <b>#{student.full_name}</b> adscrito al programa de <b>#{student.program.name}</b>.\n\n Quedo a sus ordenes para cualquier duda al respecto.", :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
        #  FIRMA
        x = x + 110
        y = y - 180
        w = 300
        h = 80
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
        pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
        pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
        # CCP
        x = 0
        y = y - 150
        w = 350
        h = 25
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        texto = "c.c.p #{supervisor.title}. #{supervisor.full_name} - Director de Tesis.\n #{student.full_name} - Estudiante"
        pdf.text_box texto, :at=>[x,y], :align=>:left, :valign=>:top, :width=>w, :height=>h, :inline_format=>true, :size=>10
      ############################### DESIGNACION DE COMITE TUTORAL ###################################
      elsif @type.eql? 6
        @render_pdf  = true
    
        s            = @c_a.committee_agreement_person.where(:attachable_type=>"Student")
        tutors       = @c_a.committee_agreement_person.where(:attachable_type=>"Staff")
        student      = Student.find(s[0].attachable_id)
        supervisor   = Staff.find(student.supervisor)
        counter      = 0

        tutors.each do |t|
          counter = counter + 1
          ############# CABECERA
          x = 250
          y = 590 #657
          w = 260
          h = 43
          size = 10
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          s_date           = @c_s.date
          last_change      = @c_s.updated_at
          today            = Date.today
          @session_type    = @c_s.get_type
          pdf.text_box "<b>Coordinación de Posgrado</b>\n<b>A#{@c_a.get_agreement_number}.#{last_change.month}<sup>#{@c_s.folio_sup}</sup>.#{last_change.year}.#{counter}</b>\nChihuahua, Chih., a #{s_date.day} de #{get_month_name(s_date.month)} de #{s_date.year}", :inline_format=>true, :at=>[x,y], :align=>:right,:valign=>:center, :width=>w, :height=>h, size: size
          ############ CABECERA
          tutor = Staff.find(t.attachable_id)
          comma_tutors = "#{tutor.title} #{tutor.full_name_cap}"
          # PRESENTE
          x = 0
          y = 505
          w = 480
          h = 15
          if comma_tutors.chop.chop.size > 85
            h = 30
          end

          if comma_tutors.chop.chop.size > 170
            h = 45
          end
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box "</b>#{comma_tutors}</b>", :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
          y = y - h
          w = 200
          h = 15
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
          # CONTENIDO
          x = 0
          y = y - 60
          w = 510
          h = 100
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box "Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado lo ha nombrado integrante del Comité Tutoral de #{student.full_name} adscrito al programa de #{student.program.name}.\n\n Quedo a sus ordenes para cualquier duda al respecto.", :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
          #  FIRMA
          x = x + 110
          y = y - 180
          w = 300
          h = 80
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
          pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
          pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
          # CCP
          x = 0
          y = y - 150
          w = 350
          h = 25
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          texto = "c.c.p #{supervisor.title}. #{supervisor.full_name} - Director de Tesis.\n #{student.full_name} - Estudiante"
          pdf.text_box texto, :at=>[x,y], :align=>:left, :valign=>:top, :width=>w, :height=>h, :inline_format=>true, :size=>10
          if !(tutors.size.eql? counter)
            pdf.start_new_page
          end
        end# tutors
      ############################### DISPENSA DE GRADO ###################################
      elsif @type.eql? 7
        @render_pdf = true
        cap1        = @c_a.committee_agreement_person.where(:attachable_type=>"Student").first
        student     = Student.find(cap1.attachable_id) rescue nil
        cap         = @c_a.committee_agreement_person.where(:attachable_type=>"Staff").first
        staff       = Staff.find(cap.attachable_id)
        notes       = @c_a.committee_agreement_note[0].notes rescue ""
        mtype       = @c_a.notes[/\[(.*?)\]/m,1] rescue ""


        if mtype.to_i.eql? 1
          mtype = "Director de Tesis"
        elsif mtype.to_i.eql? 2
          mtype = "Miembro del Comité Tutoral"
        end
        ## PRESENTACION
        x = 0
        y = 555
        w = 300
        h = 15
        pdf.text_box "</b>C. #{staff.full_name}</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true
        y = y - 15
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
        # CONTENIDO
        x = 0
        y = y - 60
        w = 510
        h = 100
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box "Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado lo ha nombrado #{mtype rescue "N.D"} del alumno #{student.full_name rescue "N.D"} adscrito al programa de #{student.program.name rescue "N.D"}.\n\n Lo anterior con base en la normatividad aplicable, articulo 11 del Reglamento de Estudios de Posgrado.", :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
        #  FIRMA
        x = x + 110
        y = y - 180
        w = 300
        h = 80
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
        pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
        pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
      ############################### DESIGNACION DE DOCENTES PARA CURSOS ###################################
      elsif @type.eql? 8
        @render_pdf = true
        cap         = @c_a.committee_agreement_person.where(:attachable_type=>"Staff").first
        staff       = Staff.find(cap.attachable_id)
        c_id        = @c_a.notes[/\[(.*?)\]/m,1] rescue ""
        course      = Course.find(c_id)
        t_id        = @c_a.auth
        term        = Term.find(t_id)
        notes       = @c_a.committee_agreement_note[0].notes rescue nil
        ## PRESENTACION
        x = 0
        y = 505
        w = 300
        h = 15
        pdf.text_box "</b>C. #{staff.full_name}</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true
        y = y - 15
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
        # CONTENIDO
        x = 0
        y = y - 60
        w = 510
        h = 170
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        text = "Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado"
        text = "#{text} lo ha nombrado docente responsable del curso #{course.name} correspondiente al ciclo escolar #{term.code} que se llevará a cabo del #{term.start_date.day} de #{get_month_name(term.start_date.month)} de #{term.start_date.year} al #{term.end_date.day} de #{get_month_name(term.end_date.month)} de #{term.end_date.year}."
        text = "#{text} \n\nEn caso de ser un curso coordinado, le pido nos haga llegar la distribución de docentes por fechas con el fin de que sean cargados en el sistema administrativo de posgrado."
        if !notes.blank?
          text = "#{text} \n\n#{notes}"
        end
        text = "#{text}\n\n Agradecemos de antemano su apoyo en la formación de recursos humanos y quedamos a sus órdenes para cualquier duda al respecto."
        pdf.text_box text, :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
        #  FIRMA
        x = x + 110
        y = y - 240
        w = 300
        h = 80
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
        pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
        pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign

      ############################### EVALUACION DE TEMARIOS PROPUESTOS ###################################
      elsif @type.eql? 9
        @render_pdf = true
        cap         = @c_a.committee_agreement_person.where(:attachable_type=>"Staff",:aux=>3).first
        staff       = Staff.find(cap.attachable_id)
        evals       = @c_a.committee_agreement_person.where(:attachable_type=>"Staff",:aux=>4)
        c_id        = @c_a.notes[/\[(.*?)\]/m,1] rescue ""
        course      = Course.find(c_id) rescue nil
        t_id        = @c_a.auth
        term        = Term.find(t_id)
        notes       = @c_a.committee_agreement_note[0].notes rescue ""
        ## PRESENTACION
        x = 0
        y = 555
        w = 300
        h = 15
        evals_text = ""
        evals.each do |e|
          st = Staff.find(e.attachable_id) 
          evals_text+="#{st.title} #{st.full_name}, "
        end
        if evals_text.chop.chop.size > 85
          h = 30
        end
        if evals_text.chop.chop.size > 170
          h = 45
        end
        pdf.text_box "<b>#{evals_text.chop.chop}</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w+200, :height=>h,:inline_format=>true
        y = y - 15
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
        # CONTENIDO
        x = 0
        y = y - 60
        w = 510
        h = 170
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        text = "Por este coducto me permito solicitar a ustedes su amable apoyo con la finalidad de evaluar el programa"
       
        if !notes.empty? && course.nil?
          text = "#{text} de la materia \"#{notes}\", propuesto por el #{staff.title} #{staff.full_name} para impartirse en el ciclo #{term.code}."
        elsif !notes.empty? && !course.nil?
          text = "#{text} de la materia \"#{notes}\" dentro del curso #{course.name}, propuesto por el #{staff.title} #{staff.full_name} para impartirse en el ciclo #{term.code}."
        elsif notes.empty? && !course.nil?
          text = "#{text} del curso #{course.name}, propuesto por el #{staff.title} #{staff.full_name} para impartirse en el ciclo #{term.code}."
        end

        text = "#{text} \n\n Agradecemos de antemano su apoyo y me encuentro a sus ordenes para cualquier duda al respecto."
        pdf.text_box text, :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
        #  FIRMA
        x = x + 110
        y = y - 200
        w = 300
        h = 80
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
        pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
        pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
      ############################### CUOTAS ###################################
      elsif @type.eql? 10
        @render_pdf = false
        ## SOLO SALE EN MINUTA
      ############################### JUSTIFICACION (ELIMINADO POR USUARIO) ###################################
      elsif @type.eql? 11
        @render_pdf = false
      ############################### PERMISO DE AUSENCIA ###################################
      elsif @type.eql? 12
        cap         = @c_a.committee_agreement_person.where(:attachable_type=>"Student").first
        student     = Student.find(cap.attachable_id)
        auth        = @c_a.auth
        notes       = @c_a.committee_agreement_note[0].notes rescue ""
        if auth.to_i.eql? 1
          @render_pdf = true
          ## PRESENTACION
          x = 0
          y = 555
          w = 300
          h = 15
          pdf.text_box "</b>C. #{student.full_name}\n Estudiante del programa de #{student.program.name}</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true
          y = y - 15
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
          # CONTENIDO
          x = 0
          y = y - 60
          w = 510
          h = 170
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          text = "Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado"
          text = "#{text} autorizó su solicitud de ausencia #{notes}."
          text = "#{text} \n\n Me encuentro a sus ordenes para cualquier duda al respecto."
          pdf.text_box text, :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
          #  FIRMA
          x = x + 110
          y = y - 200
          w = 300
          h = 80
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
          pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
          pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
        else
          @render_pdf = false
        end
      ############################### DISTRIBUCION DEL PRESUPUESTO DE BECAS ###################################
      elsif @type.eql? 13
        @render_pdf = true
        auth   = @c_a.auth
        area   = Area.find(auth)
        amount = @c_a.notes[/\[(.*?)\]/m,1] rescue ""
        notes  = @c_a.committee_agreement_note[0].notes rescue ""
        ## PRESENTACION
        x = 0
        y = 555
        w = 300
        h = 30
        pdf.text_box "</b>#{area.leader}\n Jefe de #{area.name}\n CIMAV</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true
        # CONTENIDO
        x = 0
        y = y - 60
        w = 510
        h = 170
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        text = "En seguimiento al acuerdo tomado por el Comité de Estudios de Posgrado"
        text = "#{text} para la distribución de becas de posgrado me permito informar a Usted que el monto total asignado a su departamento es por la cantidad de $#{amount}."

        if !notes.empty?
          text = "#{text}\n\n #{notes}"
        end

        text = "#{text} \n\n Es importante destacar que deberá presentarse un informe mensual del ejercicio de este presupuesto al Comité de Estudios de Posgrado en su sesión ordinaria"
        text = "#{text} \n\n Sin otro particular de momento me despido."
        pdf.text_box text, :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
        #  FIRMA
        x = x + 110
        y = y - 200
        w = 300
        h = 80
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
        pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
        pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
      ###############################  POSDOCTORADO ###################################
      elsif @type.eql? 14
        @render_pdf = true
        auth       = @c_a.auth
        area_id    = @c_a.notes[/\[(.*?)\]/m,1] rescue ""
        area       = Area.find(area_id)
        notes      = @c_a.committee_agreement_note[0].notes rescue ""
        cap        = @c_a.committee_agreement_person.where(:attachable_type=>"Internship").first
        internship = Internship.find(cap.attachable_id)
        ## PRESENTACION
        x = 0
        y = 555
        w = 300
        h = 15
        pdf.text_box "</b>#{internship.full_name}\n #{internship.institution.name}\n</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        y = y - 15
        pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
        # CONTENIDO
        x = 0
        y = y - 60
        w = 510
        h = 170
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        text = "Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado"
        text = "#{text} le ha autorizado realizar estancia posdoctoral en este Centro en el area de #{area.name}, bajo la asesoria de #{internship.staff.full_name} durante el periodo #{notes}."
        text = "#{text} \n\n Anexo formato y requisitos para el registro correspondiente y quedo a sus ordenes para cualquier duda al respecto."
        pdf.text_box text, :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
        #  FIRMA
        x = x + 110
        y = y - 200
        w = 300
        h = 80
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
        pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
        pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
      ############################### ACTUALIZACION DE NORMATIVIDAD ###################################
      elsif @type.eql? 15
        @render_pdf = false
        ## SE VA DIRECTO A MINUTA
      ############################### REVALIDACION DE CURSOS ###################################
      elsif @type.eql? 16
        @render_pdf = true
        i_id        = @c_a.notes[/\[(.*?)\]/m,1] rescue ""
        institution =  Institution.find(i_id)
        s           = @c_a.committee_agreement_person.where(:attachable_type=>"Student").first
        student     = Student.find(s.attachable_id)
        materias    = @c_a.committee_agreement_object.where(:attachable_type=>"Course")
        ## PRESENTACION
        x = 0
        y = 505
        w = 300
        h = 15
        pdf.text_box "</b>#{student.full_name}\n\n</b>", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        y = y - 15
        pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
        # CONTENIDO
        x = 0
        y = y - 35
        w = 510
        h = 170
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        text = "Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado autorizó la revalidación de los siguientes cursos:"
        pdf.text_box text, :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
        
        pdf.move_down 280
        data = []
        data << ["<b>Curso Externo</b>","<b>Equivalente en CIMAV</b>","<b>Créditos</b>"]
        
        materias.each do |m|
          m_local = Course.find(m.attachable_id)
          data << [m.aux,m_local.name,m_local.credits]
        end
        
        tabla = pdf.make_table(data,:width=>492,:cell_style=>{:size=>10,:padding=>3,:inline_format => true},:position=>:right)
        tabla.row(0).background_color = "F0F0F0"
        tabla.draw
        
        #  FIRMA
        x = x + 110
        y = y - 200
        w = 300
        h = 80
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
        pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
        pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
       
      ###############################  ###################################
      elsif @type.eql? 17
        @render_pdf = false
      ###############################  ###################################
      elsif @type.eql? 18
        @render_pdf = false
      ############################### ASIGNACION DE DIRECTOR ###################################
      elsif @type.eql? 19
        @render_pdf = true
        cap         = @c_a.committee_agreement_person.where(:attachable_type=>"Student").first
        student     = Student.find(cap.attachable_id)
        cap         = @c_a.committee_agreement_person.where(:attachable_type=>"Staff").first
        staff       = Staff.find(cap.attachable_id)
        director    = @c_a.notes[/\[(.*?)\]/m,1] rescue ""
        auth        = @c_a.auth
        if director.to_i.eql? 1
          director = "Director"
        elsif director.to_i.eql? 2
          director = "Co-Director"
        elsif director.to_i.eql? 3
          director = "Director Externo"
        end
        ## PRESENTACION
        x = 0
        y = 505
        w = 300
        h = 15
        pdf.text_box "#{staff.title} #{staff.full_name}", :at=>[x,y], :align=>:left,:valign=>:center, :width=>w, :height=>h,:inline_format=>true
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        y = y - 15
        pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
        # CONTENIDO
        x = 0
        y = y - 60
        w = 510
        h = 170
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        text = "Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado"
        if auth.to_i.eql? 1
          auth = "lo ha nombrado"
        elsif auth.to_i.eql? 2
          auth = "ha rechazado su nombramiento como"
        end
        text = "#{text} #{auth} <b>#{director}</b> de <b>#{student.full_name}</b> del programa de <b>#{student.program.name}</b>."
        text = "#{text} \n\n Me encuentro a sus ordenes para cualquier duda al respecto."
        pdf.text_box text, :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
        #  FIRMA
        x = x + 110
        y = y - 200
        w = 300
        h = 80
        if @rectangles then pdf.stroke_rectangle [x,y], w, h end
        texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
        pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
        pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
      ############################### ASUNTOS GENERALES ###################################
      #    Se ha movido a la parte de abajo con adecuaciones para imprimir en varias páginas
      #####################################################################################

      ############################### DESIGNACION DE COMITÉ DE PARES ###################################
      elsif @type.eql? 21
        @render_pdf  = true

        s            = @c_a.committee_agreement_person.where(:attachable_type=>"Student")
        tutors       = @c_a.committee_agreement_person.where(:attachable_type=>"Staff")
        student      = Student.find(s[0].attachable_id)
        supervisor   = Staff.find(student.supervisor)
        counter      = 0

        tutors.each do |t|
          counter = counter + 1
          ############# CABECERA
          x = 250
          y = 590 #657
          w = 260
          h = 43
          size = 10
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          s_date           = @c_s.date
          last_change      = @c_s.updated_at
          today            = Date.today
          @session_type    = @c_s.get_type
          pdf.text_box "<b>Coordinación de Posgrado</b>\n<b>A#{@c_a.get_agreement_number}.#{last_change.month}<sup>#{@c_s.folio_sup}</sup>.#{last_change.year}.#{counter}</b>\nChihuahua, Chih., a #{s_date.day} de #{get_month_name(s_date.month)} de #{s_date.year}", :inline_format=>true, :at=>[x,y], :align=>:right,:valign=>:center, :width=>w, :height=>h, size: size
          ############ CABECERA
          tutor = Staff.find(t.attachable_id)
          comma_tutors = "#{tutor.title} #{tutor.full_name_cap}"
          # PRESENTE
          x = 0
          y = 505
          w = 480
          h = 15
          if comma_tutors.chop.chop.size > 85
            h = 30
          end

          if comma_tutors.chop.chop.size > 170
            h = 45
          end
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box "</b>#{comma_tutors}</b>", :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
          y = y - h
          w = 200
          h = 15
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box "<b>Presente.</b>", :at=>[x,y], :align=>:left, :valign=>:center, :width=>w, :height=>h, :character_spacing=>4,:inline_format=>true
          # CONTENIDO
          x = 0
          y = y - 60
          w = 510
          h = 100
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          pdf.text_box "Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado lo ha nombrado integrante del Comité de Pares de #{student.full_name} adscrito al programa de #{student.program.name}.\n\n Quedo a sus ordenes para cualquier duda al respecto.", :at=>[x,y], :align=>:justify,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
          #  FIRMA
          x = x + 110
          y = y - 180
          w = 300
          h = 80
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          texto = "Atentamente,\n\n\n<b>#{@signer}</b>"
          pdf.text_box texto, :at=>[x,y], :align=>:center, :valign=>:top, :width=>w, :height=>h, :inline_format=>true
          pdf.image @sign,:at=>[x+@x_sign,y+@y_sign],:width=>@w_sign
          # CCP
          x = 0
          y = y - 150
          w = 350
          h = 25
          if @rectangles then pdf.stroke_rectangle [x,y], w, h end
          texto = "c.c.p #{supervisor.title}. #{supervisor.full_name} - Director de Tesis.\n #{student.full_name} - Estudiante"
          pdf.text_box texto, :at=>[x,y], :align=>:left, :valign=>:top, :width=>w, :height=>h, :inline_format=>true, :size=>10
          if !(tutors.size.eql? counter)
            pdf.start_new_page
          end
        end# tutors

      ############################### NO IDENTIFICADO ###################################
      else
        @render_pdf = false
      end

      if @render_pdf
        send_data pdf.render, type: "application/pdf", disposition: "inline"
      else
        ## sin text_box, solo text infinito # [arriba, izquierda, abajo, derecha]
        Prawn::Document.new(:background => filename, :background_scale=>0.36, :margin=>[120,60,75,55] ) do |pdf|
          ## CABECERA
          if !(@type.in? 6,21)
            size = 10
            s_date           = @c_s.date
            last_change      = @c_s.updated_at
            today            = Date.today
            @session_type    = @c_s.get_type

            pdf.text "<b>Coordinación de Posgrado</b>\n", :inline_format=>true, :align=>:right, :size=>size
            pdf.text "<b>A#{@c_a.get_agreement_number}.#{last_change.month}<sup>#{@c_s.folio_sup}</sup>.#{last_change.year}</b>\n", :inline_format=>true, :align=>:right, :size=>size
            pdf.text "Chihuahua, Chih., a #{s_date.day} de #{get_month_name(s_date.month)} de #{s_date.year}\n\n\n", :inline_format=>true, :align=>:right, :size=>size
          end
          ############################### ASUNTOS GENERALES ###################################
          if @type.eql? 20
            @render_pdf = true
            cap         = @c_a.committee_agreement_person.first
            #El destinatario es nulo?
            if cap.nil?
              destiny_name  =  "A quién corresponda."
            else
              if cap.attachable_type == "Staff"
                destiny_name  = Staff.find(cap.attachable_id).full_name  rescue "A quién corresponda."
                destiny_title = Staff.find(cap.attachable_id).title rescue "C."
              elsif cap.attachable_type == "Student"
                destiny_name  = Student.find(cap.attachable_id).full_name rescue "A quién corresponda."
                destiny_title = "C."
              end
            end

            notes       = @c_a.committee_agreement_note[0].notes rescue nil
            ## PRESENTACION
            presente = "\n\n<b>Presente.</b>\n\n"
            if destiny_name == "A quién corresponda."
              pdf.text "#{destiny_name} #{presente}", :align=>:justify,:valign=>:top, :inline_format=>true
            else
              pdf.text "#{destiny_title} #{destiny_name} #{presente}", :align=>:justify,:valign=>:top, :inline_format=>true
            end

            # CONTENIDO
            text = "Por este conducto me permito informar a Usted que el Comité de Estudios de Posgrado"
            text = "#{text} ha resuelto lo siguiente:"

            if !notes.blank?
              text = "#{text} \n\n#{notes}"
            end

            #IMPRIMIENDO 
            pdf.text text, :align=>:justify,:valign=>:top, :inline_format=>true
            #  FIRMA
            text = "\n\n\nAtentamente,\n\n\n<b>#{@signer}</b>"
            pdf.text text, :align=>:center,:valign=>:top,:inline_format=>true
            # FOOTER
            pdf.number_pages "<b>Página <page> de <total></b>", :at=>[pdf.bounds.left ,0], :align=>:center, :size=>10,:inline_format=>true
          else
            @render_pdf = false
          end

          if @render_pdf
            send_data pdf.render, type: "application/pdf", disposition: "inline"
          else
           render :text=>"Documento no disponible o no autorizado"
          end
        end#end Prawn
      end#end Else
    end

    #send_data pdf.render, type: "application/pdf", disposition: "inline"
  end

  def memorandum
    @rectangles = false
    @nbsp = Prawn::Text::NBSP

    @c_s = CommitteeSession.find(params[:s_id])
    s_date           = @c_s.date
    last_change      = @c_s.end_session
    today            = Date.today

    filename = "#{Rails.root.to_s}/private/prawn_templates/membretada.png"
    Prawn::Document.new(:background => filename, :background_scale=>0.36, :margin=>[150,60,80,60] ) do |pdf|
      if @rectangles then pdf.stroke_rectangle [x,y], w, h end
      texto = "<b>Comité de Estudios de Posgrado</b>"
      pdf.text texto, :align=>:center, :inline_format=>true, :size=>13

      if @rectangles then pdf.stroke_rectangle [x,y], w, h end
      texto = "Reunidos en la Sala de Posgrado planta alta el día <b>#{s_date.day} de #{get_month_name(s_date.month)} del año #{s_date.year},</b> a las #{s_date.hour.to_s.rjust(2,"0")}:#{s_date.min.to_s.rjust(2,"0")} h. con la asistencia de las siguientes personas: </b>"
      pdf.text texto, :align=>:justify, :valign=>:top, :inline_format=>true, :size=>10

      pdf.move_down 10
      data = []
      data << ["<b>Asistencia</b>"]
      @committee_session_attendees = CommitteeSessionAttendee.where(:committee_session_id=>@c_s.id)
      @committee_session_attendees.each do |csa|
        if csa.checked?
          data << Array(Staff.find(csa.staff_id).full_name_cap )
        end
      end

      tabla = pdf.make_table(data,:width=>492,:cell_style=>{:size=>10,:padding=>3,:inline_format => true},:position=>:right)
      tabla.row(0).background_color = "F0F0F0"
      tabla.draw

      pdf.move_down 20
      data = []
      data << ["<b>Orden del día</b>"]
      data = get_array_agreement_order(@c_s,data)
      tabla = pdf.make_table(data,:width=>492,:cell_style=>{:size=>10,:padding=>3,:inline_format => true},:position=>:right)
      tabla.row(0).background_color = "F0F0F0"
      tabla.draw

      pdf.move_down 20
      data = []
      data << [{:content=>"<b>Acuerdos</b>",:colspan=>3}]
      data << ["<b>No.de acuerdo</b>","<b>Asunto</b>","<b>Resolución</b>"]
      data = get_array_agreement(@c_s,last_change,data)
      data = get_general_issues(@c_s,last_change,data)

      tabla = pdf.make_table(data,:width=>492,:cell_style=>{:size=>10,:padding=>3,:inline_format => true},:position=>:right,:column_widths=>[80,206,206])
      tabla.rows(0).background_color = "F0F0F0"
      tabla.draw
      pdf.move_down 10
      pdf.text "La sesión terminó a las #{last_change.hour.to_s.rjust(2,"0")}:#{last_change.min.to_s.rjust(2,"0")} h"
      send_data pdf.render, type: "application/pdf", disposition: "inline"
    end
  end

  def get_array_agreement_order(c_s,data)
    @committee_agreements = CommitteeAgreement.where(:committee_session_id=>c_s.id)
    repeaters = Array.new
    @committee_agreements.each do |ca|
      involved = ""
      insert   = false
      cat      =  CommitteeAgreementType.find(ca.committee_agreement_type_id)
      if cat.id.eql? 1 ## Nuevo ingreso
        name = Applicant.find(ca.committee_agreement_person[0].attachable_id).full_name
        involved = "de #{name} "
        insert   = true
      elsif cat.id.eql? 2 ## Permanencia
        name = Student.find(ca.committee_agreement_person[0].attachable_id).full_name
        involved = "de #{name} "
        insert   = true
      elsif cat.id.eql? 4 ## Cambio de director de tesis
        name = Student.find(ca.committee_agreement_person.where(:attachable_type=>"Student")[0].attachable_id).full_name
        involved = "de #{name} "
        insert   = true
      elsif cat.id.eql? 5 ## Designación de sinodales
        name = Student.find(ca.committee_agreement_person.where(:attachable_type=>"Student")[0].attachable_id).full_name
        involved = "de #{name}"
        insert   = true
      elsif cat.id.eql? 6 ## Designación de comité tutoral
        name = Student.find(ca.committee_agreement_person.where(:attachable_type=>"Student")[0].attachable_id).full_name
        involved = "de #{name}"
        insert   = true
      elsif cat.id.eql? 7 ## Dispensa de grado para personal academico
        name = Staff.find(ca.committee_agreement_person.where(:attachable_type=>"Staff")[0].attachable_id).full_name
        involved = "de #{name}"
        insert   = true
      elsif cat.id.eql? 12  ## Permiso de ausencia
        name = Student.find(ca.committee_agreement_person.where(:attachable_type=>"Student")[0].attachable_id).full_name
        involved = "para #{name}"
        insert   = true
      else
        involved = ""
        if repeaters.include? cat.id
          insert   = false
        else
          repeaters << cat.id
          insert   = true
        end
      end

      if insert
        data << Array("#{cat.description} #{involved}")
      end
    end
    return data
  end

  def get_array_agreement(c_s,last_change,data)
    @committee_agreements = CommitteeAgreement.where(:committee_session_id=>c_s.id)
    @committee_agreements.each do |ca|
      authorized = ""
      show = true
      cat   = CommitteeAgreementType.find(ca.committee_agreement_type_id)
      issue = "<b><i>#{cat.description}</i></b>"

      if cat.id.eql? 1 ## Nuevo ingreso
        app  = Applicant.find(ca.committee_agreement_person[0].attachable_id)
        issue = "#{issue}\n\n<b>#{app.full_name}</b> al programa <b>#{app.program.name}</b>"
        if ca.auth.to_i.eql? 1
          authorized = "<b>Autorizado</b>"
        elsif ca.auth.to_i.eql? 2
          authorized = "<b>Rechazado</b>"
        end
      elsif cat.id.eql? 2 ## Permanencia
        name       = Student.find(ca.committee_agreement_person[0].attachable_id).full_name
        l_date     = Date.parse(ca.notes[/\[(.*?)\]/m,1]) rescue ""
        issue = "#{issue}\n\n<b>#{name}</b>\n\n"
        if ca.auth.to_i.eql? 1
          authorized = "<b>Autorizado</b>\nCon prórroga para entregar requisitos de titulación a mas tardar el #{l_date.day} de #{get_month_name(l_date.month)} de #{l_date.year}"
        elsif ca.auth.to_i.eql? 2
          authorized = "<b>Rechazado</b>"
        elsif ca.auth.to_i.eql? 3
          authorized = "<b>Baja explícita</b>"
        end
      elsif cat.id.eql? 3 ## Cambio de programa
        s       = ca.committee_agreement_person.where(:attachable_type=>"Student")
        student = Student.find(s[0].attachable_id)
        program = Program.find(ca.auth)
        name    = Student.find(ca.committee_agreement_person[0].attachable_id).full_name
        issue = "#{issue}\n\n<b>#{name}</b>\n\n"
        authorized = "<b>Autorizado</b>\n\nPara el programa #{program.name}"
      elsif cat.id.eql? 4 ## Cambio de director de tesis
        name  = Student.find(ca.committee_agreement_person.where(:attachable_type=>"Student")[0].attachable_id).full_name
        name1 = Staff.find(ca.committee_agreement_person.where(:attachable_type=>"Staff")[0].attachable_id).full_name_cap rescue nil
        issue = "#{issue}\n\n <b>#{name}</b>\n\n"
        if !name1.nil?
          authorized = "<b>Se autorizó como director de tesis a: #{name1}</b>"
        else
          authorized = "<b>Rechazado</b>"
        end
      elsif cat.id.eql? 5 ## Designación de sinodales
        student  = Student.find(ca.committee_agreement_person.where(:attachable_type=>"Student")[0].attachable_id)
        name     = student.full_name
        director = Staff.find(student.supervisor).full_name_cap rescue "N.D."
        issue = "#{issue}\n\n <b>#{name}</b>\n\n Director de tesis: #{director} \n\n"
        sinodales = ""
        ca.committee_agreement_person.where(:attachable_type=>"Staff").each do |cap|
          s = Staff.find(cap.attachable_id)
          aux = ""
          if cap.aux.eql? 2
            aux = "(suplente)"
          end
          
          sinodales = "#{sinodales} #{s.full_name_cap} #{aux}\n"
        end
        if !sinodales.eql? ""
          authorized = "<b>Se autorizó el siguiente sínodo:</b>\n\n#{sinodales}\n\n"
        else
          authorized = "<b>Rechazado</b>"
        end
      elsif cat.id.eql? 6 ## Designación de comité tutoral
        student  = Student.find(ca.committee_agreement_person.where(:attachable_type=>"Student")[0].attachable_id)
        name     = student.full_name
        director = Staff.find(student.supervisor).full_name_cap rescue "N.D."
        issue = "#{issue}\n\n <b>#{name}</b>\n\n Director de tesis: #{director} \n\n"
        sinodales = ""
        ca.committee_agreement_person.where(:attachable_type=>"Staff").each do |s|
          s = Staff.find(s.attachable_id)
          sinodales = "#{sinodales} #{s.full_name_cap}\n"
        end
        if !sinodales.eql? ""
          authorized = "<b>Se autorizó el siguiente comité tutoral:</b>\n\n#{sinodales}\n\n"
        else
          authorized = "<b>Rechazado</b>"
        end
      elsif cat.id.eql? 7 ## Dispensa de grado para personal academico
        cap1        = ca.committee_agreement_person.where(:attachable_type=>"Student").first
        student     = Student.find(cap1.attachable_id) rescue nil
        cap         = ca.committee_agreement_person.where(:attachable_type=>"Staff").first
        staff       = Staff.find(cap.attachable_id)
        notes       = ca.committee_agreement_note[0].notes rescue ""
        mtype       = ca.notes[/\[(.*?)\]/m,1] rescue ""

        if mtype.to_i.eql? 1
          mtype = "Director de Tesis"
        elsif mtype.to_i.eql? 2
          mtype = "Miembro del Comité Tutoral"
        end
        issue = "#{issue}\n\n <b>#{staff.title} #{staff.full_name_cap}</b>\n\n"
        if ca.auth.to_i.eql? 1
          authorized = "<b>Autorizado</b>\n Como #{mtype} del alumno #{student.full_name}. #{notes}"
        elsif ca.auth.to_i.eql? 2
          authorized = "<b>Rechazado</b>\n#{notes}"
        end
      elsif cat.id.eql? 8 ## Designacion de docentes para cursos
        cap         = ca.committee_agreement_person.where(:attachable_type=>"Staff").first
        staff       = Staff.find(cap.attachable_id)
        c_id        = ca.notes[/\[(.*?)\]/m,1] rescue ""
        course      = Course.find(c_id)
        t_id        = ca.auth
        term        = Term.find(t_id)
        issue = "#{issue}\n\n <b>#{staff.title} #{staff.full_name_cap}</b>\n\n Curso: #{course.name}\n"
        authorized = "<b>Autorizado</b>\n Para el curso #{course.name} correspondiente al ciclo escolar <b>#{term.name}</b> del programa #{term.program.name}."
      elsif cat.id.eql? 9 ## Evaluación de temarios propuesto 
        cap         = ca.committee_agreement_person.where(:attachable_type=>"Staff",:aux=>3).first
        staff       = Staff.find(cap.attachable_id)
        c_id        = ca.notes[/\[(.*?)\]/m,1] rescue ""
        course      = Course.find(c_id) rescue nil
        t_id        = ca.auth
        term        = Term.find(t_id)
        notes       = ca.committee_agreement_note[0].notes rescue ""
        
        if !notes.empty? && course.nil?
          issue = "#{issue}\n\n <b>Curso: #{notes} - #{term.program.prefix} #{term.code}</b>\nDocente: #{staff.title} #{staff.full_name_cap}"
        elsif !notes.empty? && !course.nil?
          issue = "#{issue}\n\n <b>Curso: #{course.name} - #{notes} - #{term.program.prefix} #{term.code}</b>\nDocente: #{staff.title} #{staff.full_name_cap}"
        elsif notes.empty? && !course.nil?
          issue = "#{issue}\n\n <b>Curso: #{course.name} - #{term.program.prefix} #{term.code}</b>\nDocente: #{staff.title} #{staff.full_name_cap}"
        end

        authorized = "\n\nEvaluadores:\n"
        ca.committee_agreement_person.where(:attachable_type=>"Staff",:aux=>4).each do |st|
          s = Staff.find(st.attachable_id) 
          authorized = "#{authorized}#{s.title} #{s.full_name}\n"
        end
      elsif cat.id.eql? 10 ## Cuotas
        inscripciones= ca.auth rescue ""
        titulaciones = ca.notes[/\[(.*?)\]/m,1] rescue ""
        notes        = ca.committee_agreement_note[0].notes rescue ""
        issue = "#{issue}\n\n <b></b>\n\n"
        authorized = "<b>Autorizado</b>\n Con un monto de inscripción de $#{inscripciones} y un monto de titulacion de $#{titulaciones}. #{notes}"
      elsif cat.id.eql? 12  ## Permiso de ausencia
        cap         = ca.committee_agreement_person.where(:attachable_type=>"Student").first
        student     = Student.find(cap.attachable_id)
        auth        = ca.auth
        notes       = ca.committee_agreement_note[0].notes rescue ""
        issue = "#{issue}\n\n <b>Estudiante #{student.full_name}</b>\n\n"
        if ca.auth.to_i.eql? 1
          authorized = "<b>Autorizado</b>\n #{notes}"
        elsif ca.auth.to_i.eql? 2
          authorized = "<b>Rechazado</b>\n #{notes}"
        end
      elsif cat.id.eql? 13 ## Presupuesto de becas
        auth   = ca.auth
        area   = Area.find(auth)
        amount = ca.notes[/\[(.*?)\]/m,1] rescue ""
        notes  = ca.committee_agreement_note[0].notes rescue ""
        issue = "#{issue}\n\n <b>#{area.name}</b>\n\n#{area.leader}"
        authorized = "<b>Autorizado</b>\n Con un monto de #{amount}. #{notes}"
      elsif cat.id.eql? 14 ## Posdoctorado
        auth       = ca.auth
        area_id    = ca.notes[/\[(.*?)\]/m,1] rescue ""
        area       = Area.find(area_id)
        notes      = ca.committee_agreement_note[0].notes rescue ""
        cap        = ca.committee_agreement_person.where(:attachable_type=>"Internship").first
        internship = Internship.find(cap.attachable_id)
        issue      = "#{issue}\n\n <b>#{internship.full_name}</b>"
        if ca.auth.to_i.eql? 1
          authorized = "<b>Autorizado</b>\n Para el #{area.name} bajo la asesoria de #{area.leader} #{notes}"
        elsif ca.auth.to_i.eql? 2
          authorized = "<b>Rechazado</b>\n #{notes}"
        end
      elsif cat.id.eql? 15 ## Actualizacion de normatividad
        authorized = CommitteeAgreementNote.where(:committee_agreement_id=>ca.id)[0].notes rescue nil
      elsif cat.id.eql? 16 ## Revalidacion de cursos
        cap         = ca.committee_agreement_person.where(:attachable_type=>"Student").first
        cac         = ca.committee_agreement_object.where(:attachable_type=>"Course")
        student     = Student.find(cap.attachable_id)

        courses = ""
        cac.each do |c|
          name    = Course.find(c.attachable_id).name rescue "N.D."
          courses = "#{courses} <br>* El curso <b>#{name}</b> por el curso externo <b>#{c.aux}</b>"
        end
        
        issue = "#{issue}\n\n <b>Estudiante: #{student.full_name}</b>\n\n"
        authorized = "<b>Autorizado:</b><br>#{courses}"
      elsif cat.id.eql? 19 ## Asignacion de director
        cap         = ca.committee_agreement_person.where(:attachable_type=>"Student").first
        student     = Student.find(cap.attachable_id)
        cap         = ca.committee_agreement_person.where(:attachable_type=>"Staff").first
        staff       = Staff.find(cap.attachable_id)
        auth        = ca.auth
        director    = ca.notes[/\[(.*?)\]/m,1] rescue ""
        if director.to_i.eql? 1
          director = "Director"
        elsif director.to_i.eql? 2
          director = "Co-Director"
        elsif director.to_i.eql? 3
          director = "Director Externo"
        end
        issue = "#{issue}\n\n <b>#{staff.full_name} (#{director})</b>\n <b>#{student.full_name}</b> \n<b>#{student.program.name}</b>\n\n"
        if ca.auth.to_i.eql? 1
          authorized = "<b>Autorizado</b>\n"
        elsif ca.auth.to_i.eql? 2
          authorized = "<b>Rechazado</b>\n"
        end
      elsif cat.id.eql? 20 ## ASuntos generales
        show = false
      end


      if show
        data << ["<b>A#{ca.get_agreement_number}.#{last_change.month}<sup>#{c_s.folio_sup}</sup>.#{last_change.year}</b>",issue,authorized]
      end
    end

    return data
  end

  def get_general_issues(c_s,last_change,data)
    issue = "<b><i>Asuntos Generales</i></b>"
    authorized = ""
    counter    = 1
    @committee_agreements = CommitteeAgreement.where(:committee_session_id=>c_s.id)
    @committee_agreements.where(:committee_agreement_type_id=>20).each do |ca|
      notes      = ca.committee_agreement_note[0].notes rescue ""
      authorized = " Para:<b> #{ca.committee_agreement_person[0].attachable.full_name}</b>\n\n #{notes}"
      counter = counter + 1
      data << ["<b>A#{ca.id}.#{last_change.month}<sup>#{c_s.folio_sup}</sup>.#{last_change.year}</b>",issue,authorized]
    end

    return data
  end

end
