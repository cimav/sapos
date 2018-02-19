# coding: utf-8
class TeacherEvaluationsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json, :csv

  def download
    tc = TermCourse.find(params[:tc_id])
    Prawn::Document.new do |pdf|
      pdf.text "ENCUESTA DE EVALUACIÓN DOCENTE", :align=>:center, :style=>:bold
      pdf.text "PROMEDIO FINAL\n\n", :align=>:center, :style=>:bold
      pdf.text "Materia: #{tc.course.name}"
      pdf.text "Docente: #{tc.staff.full_name}"
      pdf.text "Periodo: #{tc.term.name}"

      promedio= 3.5

      data = []
      data << [{:content=>""},{:content=>"<b>Promedio</b>",:align=>:center}]

      averages = get_averages(tc)

      question = "Muestra tener conocimientos en el área académica de la materia."
      data << [question,TeacherEvaluation::ANSWERS[averages["question1"]]]
      question = "Utiliza recursos didácticos adecuados, tanto para la presentación de los contenidos, como para la práctica."
      data << [question,TeacherEvaluation::ANSWERS[averages["question2"]]]
      question = "La atención fuera de clases (asesorías, tutorías, etc.) es adecuada."
      data << [question,TeacherEvaluation::ANSWERS[averages["question3"]]]
      question = "Asiste puntualmente a clases."
      data << [question,TeacherEvaluation::ANSWERS[averages["question4"]]]
      question = "Cumple con las actividades programadas."
      data << [question,TeacherEvaluation::ANSWERS[averages["question5"]]]
      question = "Se caracteriza por combinar e integrar en su desempeño académico la docencia y la investigación."
      data << [question,TeacherEvaluation::ANSWERS[averages["question6"]]]
      question = "Comparte información y experiencia con los alumnos."
      data << [question,TeacherEvaluation::ANSWERS[averages["question7"]]]
      question = "Mantiene el interés de los alumnos, usando estrategias adecuadas."
      data << [question,TeacherEvaluation::ANSWERS[averages["question8"]]]
      question = "Fomenta el respeto y la colaboración entre alumnos y acepta sus sugerencias y aportaciones."
      data << [question,TeacherEvaluation::ANSWERS[averages["question9"]]]
      question = "Las evaluaciones (trabajos, prácticas y exámenes) son objetivas."
      data << [question,TeacherEvaluation::ANSWERS[averages["question10"]]]
      question = "Es respetuoso con los alumnos(as)"
      data << [question,TeacherEvaluation::ANSWERS[averages["question11"]]]
      question = "Proporciona información al alumno sobre la ejecución de las tareas y como puede mejorarlas."
      data << [question,TeacherEvaluation::ANSWERS[averages["question12"]]]

      tabla = pdf.make_table(data,:width=>537,:cell_style=>{:size=>10,:padding=>2,:inline_format => true,:border_width=>1},:position=>:center)
      tabla.draw

      #send_data pdf.render, type: "application/pdf", disposition: "attachment"
      send_data pdf.render, type: "application/pdf", disposition: "inline"
    end#

  end#download

  def get_averages(tc)
    averages   = Hash.new
    tc.teacher_evaluations.each do |te|
      (1..12).each do |n|
        averages["sum#{n}"] = averages["sum#{n}"].to_f + te["question#{n}"].to_f
      end
    end
      
    (1..12).each do |n|
      averages["question#{n}"] = (averages["sum#{n}"]/tc.teacher_evaluations.size).to_f.round
      averages.delete("sum#{n}")
    end
    
    return averages
  end#get_averages
  
end#class
