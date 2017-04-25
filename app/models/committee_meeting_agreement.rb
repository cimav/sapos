class CommitteeMeetingAgreement < ActiveRecord::Base
  belongs_to :committee_meeting
  has_many :committee_file#, :dependent => :destroy
  has_many :committee_response#, :dependent => :destroy
  attr_accessible :description, :status, :committee_meeting_id

  AWAITING_RESPONSE = 0
  APPROVED = 1
  REJECTED = 2
  SENT_TO_COMMITTEE = 3



  STATUS = {
      AWAITING_RESPONSE => 'En espera de respuesta',
      APPROVED => 'Aprobado',
      REJECTED => 'Rechazado',
      SENT_TO_COMMITTEE => 'Enviado a comité'
  }

  def get_status
    STATUS[status]
  end

end
