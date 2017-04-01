class CommitteeMeeting < ActiveRecord::Base
  attr_accessible :date, :status, :type
  has_many :committee_meeting_agreement, :dependent => :destroy

  OPEN = 1
  CLOSE = 2

  ORDINARY = 1
  EXTRAORDINARY = 2

  TYPE = {
      ORDINARY => 'Ordinaria',
      EXTRAORDINARY => 'Extraordinaria',
  }

  STATUS = {
      OPEN => 'Abierta',
      CLOSE => 'Finalizada'
  }

  def get_status
    STATUS[status]
  end
end
