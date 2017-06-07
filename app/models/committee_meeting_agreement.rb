class CommitteeMeetingAgreement < ActiveRecord::Base
  belongs_to :committee_meeting
  has_many :committee_file#, :dependent => :destroy
  has_many :committee_response#, :dependent => :destroy
  attr_accessible :description, :status, :committee_meeting_id, :agreement_type

  AWAITING_RESPONSE = 0
  APPROVED = 1
  REJECTED = 2
  SENT_TO_COMMITTEE = 3

  NUEVO_INGRESO = 1
  PERMANENCIA = 2
  CAMBIO_PROGRAMA = 3
  CAMBIO_DIRECTOR_TESIS = 4
  DESIG_SINODALES = 5
  DESIG_COMITE_TUTORAL = 6
  DOCENTE_CURSO = 7
  AUTORIZACION_MATERIA = 8
  CUOTAS = 9
  PERMISIO_AUSENCIA = 10
  PRESUPUESTO_BECAS = 11
  POSDOCTORADO = 12
  ACTUALIZACION_NORMATIVIDAD =13
  REVALIDACION_CURSO = 14
  DESIG_COMITE_INGRESO = 15
  AUT_PROTOCOLO_MAESTRIA = 16
  ASIG_DIRECTOR = 17
  ASUNTOS_GENERALES =18


  STATUS = {
      AWAITING_RESPONSE => 'En espera de respuesta',
      APPROVED => 'Aprobado',
      REJECTED => 'Rechazado',
      SENT_TO_COMMITTEE => 'Enviado a comité'
  }

  AGREEMENT_TYPE = {
      NUEVO_INGRESO => 'Nuevo ingreso',
  PERMANENCIA => 'Permanencia',
  CAMBIO_PROGRAMA => 'cambio de programa',
  CAMBIO_DIRECTOR_TESIS => 'cambio de director de tesis',
  DESIG_SINODALES => 'designacion de sinodales',
  DESIG_COMITE_TUTORAL => 'designacion comité tutoral',
  DOCENTE_CURSO => 'Designacion de docentes para curso',
  AUTORIZACION_MATERIA => 'Autorización de materias nuevas',
  CUOTAS => 'Cuotas',
  PERMISIO_AUSENCIA => 'Permiso de ausencia',
  PRESUPUESTO_BECAS => 'Distribución del presupuesto de becas',
  POSDOCTORADO => 'Posdoctorado',
  ACTUALIZACION_NORMATIVIDAD => 'Actualización de normatividad',
  REVALIDACION_CURSO => 'Revalidación de cursos',
  DESIG_COMITE_INGRESO => 'Designación de comité de ingreso',
  AUT_PROTOCOLO_MAESTRIA => 'Autorización de protocolo de maestría',
  ASIG_DIRECTOR => 'Asignación de director',
  ASUNTOS_GENERALES => 'Asuntos generales'
  }


  def get_status
    STATUS[status]
  end

  def get_type
    AGREEMENT_TYPE[agreement_type]
  end

end
