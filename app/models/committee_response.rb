class CommitteeResponse < ActiveRecord::Base
  belongs_to :committee_meeting_agreement
  belongs_to :committee_member
  attr_accessible :answer, :note

  AWAITING_RESPONSE = 0
  APPROVED = 1
  REJECTED = 2
  SENT_TO_COMMITTEE = 3



  ANSWER = {
      AWAITING_RESPONSE => 'En espera de respuesta',
      APPROVED => 'Aprobado',
      REJECTED => 'Rechazado',
      SENT_TO_COMMITTEE => 'Enviado a comité'
  }

  def get_answer
    STATUS[answer]
  end
end
