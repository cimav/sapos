# coding: utf-8
# rake procotol:create[1,2,3] where 1=p_id=protocol_id 2=s_id=staff_id 3=a_id=advance_id

namespace :protocol do
  desc "Generate protocol pdf documents"
  task :create, [:p_id,:s_id,:a_id] => :environment do |t,args|
    protocol = Protocol.find(args[:p_id])
    staff    = Staff.find(args[:s_id])
    advance  = Advance.find(args[:a_id])

    @r_root  = Rails.root.to_s
    @rectangles = true

    supervisor      = Staff.find(advance.student.supervisor) rescue nil 
    supervisor_name = supervisor.full_name rescue "N.D"
    supervisor_area = supervisor.area.name rescue "N.D"

    created = "#{advance.created_at.day} de #{get_month_name(advance.created_at.month)} de #{advance.created_at.year}"
    
    filename  = "#{Settings.sapos_route}/private/files/students/#{advance.student.id}"
 
    if advance.advance_type.eql? 2
      pdf_route = "#{filename}/protocol-#{advance.id}-#{staff.id}.pdf"
    elsif advance.advance_type.eql? 3
      pdf_route = "#{filename}/seminar-#{advance.id}-#{staff.id}.pdf"
    end 

    if File.exist?(pdf_route)
      File.delete(pdf_route)
    end 

    pdf = Prawn::Document.new(:margin=>[20,43,43,43])
    size = 14

    if advance.advance_type.eql? 2
      pdf.move_down 30
      text = "FORMATO P-MA-E"
      pdf.text text, :size=>size, :style=> :bold, :align=> :center

      pdf.move_down 1
      text = "EVALUACIÓN PROTOCOLOS"
      pdf.text text ,:size=>size, :style=> :bold, :align=> :center
    elsif advance.advance_type.eql? 3
      pdf.move_down 31
      text = "SEMINARIO FINAL"
      pdf.text text ,:size=>size, :style=> :bold, :align=> :center
    end 

    size = 11

    pdf.move_down 10
    data = []
    data << [{:content=>"Fecha de Evaluación: #{created}",:colspan=>2,:align=>:right}]
    data << [{:content=>" ",:colspan=>2}]
    data << ["Nombre del Alumno:",advance.student.full_name]
    data << ["Nombre del Director de Tesis:",supervisor_name]
    data << ["Departamento:",supervisor_area]
    data << ["Programa:",advance.student.program.name]
    data << ["Título de la Tesis:",advance.title]

    tabla = pdf.make_table(data,:width=>530,:cell_style=>{:size=>size,:padding=>2,:inline_format => true,:border_width=>0},:position=>:center,:column_widths=>[165,365])
    tabla.draw

    pdf.move_down 10

     icon_empty = pdf.table_icon('fa-square-o')
     icon_ok    = pdf.table_icon('fa-check-square-o')
     content1   = icon_empty

    protocol.reload.answers.each do |a|
      pdf.move_down 10
      
      question = Question.find(a.question_id)
      text = Question.find(a.question_id).question rescue "N.D"
      pdf.text text, :size=>size, :style=>:bold

      data = []

      if question.question_type.to_i.eql? 1  ## multiple option
        (a.answer.eql? 4) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Excelente"]
        (a.answer.eql? 3) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Bien"]
        (a.answer.eql? 2) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Regular"]
        (a.answer.eql? 1) ? content1 = icon_ok : content1 = icon_empty
        data << [content1,"Deficiente"]
      elsif question.question_type.to_i.eql? 2 ## text
        answer = a.comments rescue "n.d."
        data << [{:content=>"#{answer}",:colspan=>2}]
      elsif question.question_type.to_i.eql? 3 ## grade
        answer = a.answer rescue "n.d."
        data << [{:content=>"#{answer}",:colspan=>2}]
      end 
        tabla = pdf.make_table(data,:width=>530,:cell_style=>{:size=>size,:padding=>2,:inline_format => true,:border_width=>0},:position=>:center,:column_widths=>[30,500])

      tabla.draw
    end

    pdf.move_down 10
    data = []
    data << [{:content=>"<b>Resultado</b>",:colspan=>2}]

    icon_empty = pdf.table_icon('fa-square-o')
    icon_ok    = pdf.table_icon('fa-check-square-o')
    content1   = icon_empty
 
    if advance.advance_type.eql? 2 #protocol
      (protocol.grade_status.eql? 1) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,"Aprobado"]
      (protocol.grade_status.eql? 2) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,"No aprobado"]
    elsif advance.advance_type.eql? 3 #seminar
      (protocol.grade_status.eql? 1) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,{:content=>"Aprobado",:align=>:left}]
      (protocol.grade_status.eql? 2) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,"No aprobado"]
      (protocol.grade_status.eql? 3) ? content1 = icon_ok : content1 = icon_empty
      data << [content1,"Con Recomendaciones"]
    end

    tabla = pdf.make_table(data,:width=>300,:cell_style=>{:size=>size,:padding=>2,:inline_format => true,:border_width=>0},:position=>:left,:column_widths=>[30,270])
    tabla.draw
    
    pdf.text "\nCon promedio de #{protocol.grade}"

    pdf.render_file "#{pdf_route}"
 
  end ## task create
end ## namespace

  def get_month_name(number)
    months = ["enero","febrero","marzo","abril","mayo","junio","julio","agosto","septiembre","octubre","noviembre","diciembre"]
    name = months[number - 1]
    return name
  end

