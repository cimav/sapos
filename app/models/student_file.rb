# coding: utf-8
class StudentFile < ActiveRecord::Base
  attr_accessible :id,:student_id,:description,:file,:created_at,:updated_at

  default_scope joins(:student).where('students.deleted=?',0).readonly(false)

  belongs_to :student

  mount_uploader :file, StudentFileUploader

  validates :description, :presence => true
  before_destroy :delete_linked_file

    CONACYT     = 1
    TRAJECTORY  = 2
    COMMITTEE   = 3
    GRADUATE    = 4
    DEGREE      = 5
    DIVULGATION = 6

    ACCEPTANCE       = 1
    DRAFT            = 2
    PREV_GRADE       = 3
    VOTER_CARD       = 4
    FULL_TIME        = 5
    MIXED            = 6
    PERFORMANCE      = 7
    REGISTRATION     = 8
    OTHER_TRAJECTORY = 9
    COMMITTEE_P      = 10
    COPYRIGHT        = 11
    GRADE_EXAM_AUTH  = 12
    PROTEST_EXAM     = 13
    MINUTE_AGREEMENTS= 14
    GRADE_EXAM_REQ   = 15
    FINAL_REPORT_SEM = 16
    TOEFL            = 17
    KARDEX           = 18
    ASSISTANCE_CERT  = 19
    PAYMENT_CARD_D   = 20
    THESIS_ABSTRACT  = 21
    CONACYT_R_CARD   = 22
    DEGREE_D         = 23
    DIVULGATION_D    = 24
    OTHER_CONACYT    = 25
    OTHER_COMMITTEE  = 26
    OTHER_GRADUATE   = 27
    OTHER_DEGREE     = 28
    OTHER_DIVULGATION= 29

    FOLDERS = {
      CONACYT     => 'Expediente CONACyT',
      TRAJECTORY  => 'Expediente de trayectoria',
      COMMITTEE   => 'Acuerdos del Comité de Estudios de Posgrado',
      GRADUATE    => 'Expediente de egreso',
      DEGREE      => 'Expediente de titulación',
      DIVULGATION => 'Expediente de divulgación'
    }

    FILE_TYPE = [
      {:id=>ACCEPTANCE,       :description=>'Carta de aceptación al programa de Posgrado',:folder=>CONACYT},
      {:id=> DRAFT,           :description=>'Evaluación de anteproyecto (Solo para doctorados)',:folder=>CONACYT},
      {:id=>PREV_GRADE,       :description=>'Certificado de estudios del grado anterior',:folder=>CONACYT},
      {:id=>VOTER_CARD,       :description=>'Credencial de elector',:folder=>CONACYT},
      {:id=>FULL_TIME,        :description=>'Carta de dedicación exclusiva',:folder=>CONACYT},
      {:id=>MIXED,            :description=>'beca mixta',:folder=>CONACYT},
      {:id=>PERFORMANCE,      :description=>'Desempeño del becario',:folder=>CONACYT},
      {:id=>REGISTRATION,     :description=>'Expediente de inscripción (Formato de inscripción, formato de datos personales, consentimiento individual, minimos probatorios)',:folder=>TRAJECTORY},
      {:id=>OTHER_TRAJECTORY, :description=> 'otros', :folder=>TRAJECTORY},
      {:id=>COMMITTEE_P,      :description=> 'Boleta de selección de director de tesis, becas fiscales, etc.', :folder=>COMMITTEE},
      {:id=>COPYRIGHT,        :description=> 'Carta de sesión de derechos de autor', :folder=>GRADUATE},
      {:id=>GRADE_EXAM_AUTH,  :description=> 'Oficio de autorización de examen de grado', :folder=>GRADUATE},
      {:id=>PROTEST_EXAM,     :description=> 'Protesta de examen', :folder=>GRADUATE},
      {:id=>MINUTE_AGREEMENTS,:description=> 'Minuta de acuerdos', :folder=>GRADUATE},
      {:id=>GRADE_EXAM_REQ,   :description=> 'Solicitud de examen de grado', :folder=>GRADUATE},
      {:id=>FINAL_REPORT_SEM, :description=> 'Reporte de seminario final', :folder=>GRADUATE},
      {:id=>TOEFL,            :description=> 'Toefl', :folder=>GRADUATE},
      {:id=>KARDEX,           :description=> 'Kardex', :folder=>GRADUATE},
      {:id=>ASSISTANCE_CERT,  :description=> 'Constacias de asistencia a seminarios (una por el Coordinador de Seminarios y otra por el área de Posgrado)', :folder=>GRADUATE},
      {:id=>PAYMENT_CARD_D ,  :description=> 'Ficha de pago de titulación', :folder=>GRADUATE},
      {:id=>THESIS_ABSTRACT,  :description=> 'Portada y Resumen de Tesis', :folder=>GRADUATE},
      {:id=>CONACYT_R_CARD,   :description=> 'Carta de reconocimiento CONACyT  del Posgrado obtenido', :folder=>GRADUATE},
      {:id=>DEGREE_D,         :description=> 'Copias de titulo, certificado, acta de grado, cédula y carta de recibido de cocumentos originales
  ', :folder=>DEGREE},
      {:id=>DIVULGATION_D,    :description=> 'Artículos, reconocimientos, congresos,  etc.', :folder=>DIVULGATION},
      {:id=>OTHER_CONACYT,    :description=> 'Otros', :folder=>CONACYT},
      {:id=>OTHER_COMMITTEE,  :description=> 'Otros', :folder=>COMMITTEE},
      {:id=>OTHER_GRADUATE,   :description=> 'Otros', :folder=>GRADUATE},
      {:id=>OTHER_DEGREE,     :description=> 'Otros', :folder=>DEGREE},
      {:id=>OTHER_DIVULGATION,:description=> 'Otros', :folder=>DIVULGATION},
    ]

  def delete_linked_file
    self.remove_file!
  end
end
