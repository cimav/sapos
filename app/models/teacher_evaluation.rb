class TeacherEvaluation < ActiveRecord::Base
  belongs_to :staff
  belongs_to :term_course

  ALWAYS = 4
  ALMOST_ALWAYS = 3
  SOMETIMES = 2
  RARELY = 1
  NEVER = 0

  ANSWERS = {
      ALWAYS => "Siempre",
      ALMOST_ALWAYS => "Casi siempre",
      SOMETIMES => "A veces",
      RARELY => "Casi nunca",
      NEVER => "Nunca"}

  def get_answer(answer)
    ANSWERS[answer]
  end

  def question_text(number)
    case number
      when 1
        "Muestra tener conocimientos en el área académica de la materia."
      when 2
        "Utiliza recursos didácticos adecuados, tanto para la presentación de los contenidos, como para la práctica."
      when 3
        "La atención fuera de clases (asesorías, tutorías, etc.) es la adecuada."
      when 4
        "Asiste puntualmente a clases."
      when 5
        "Cumple con las actividades programadas."
      when 6
        "Se caracteriza por combinar e integrar en su desempeño académico la docencia y la investigación."
      when 7
        "Comparte información y experiencia con los alumnos."
      when 8
        "Mantiene el interés de los alumnos, usando estrategias adecuadas."
      when 9
        "Fomenta el respeto y la colaboración entre alumnos y acepta sus sugerencias y aportaciones."
      when 10
        "Las evaluaciones (trabajos, prácticas y exámenes) son objetivas."
      when 11
        "El respetuoso con los alumnos (as)"
      when 12
        "Proporciona información al alumno sobre la ejecución de las tareas y cómo puede mejorarlas."
    end
  end
end
