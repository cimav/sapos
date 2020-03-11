class CommitteeMember < ActiveRecord::Base
  belongs_to :staff
  has_many :committee_response, :dependent => :destroy
  attr_accessible :status

  ACTIVE = 1
  INACTIVE = 2


  STATUS = {
      ACTIVE => 'Activo',
      INACTIVE => 'Inactivo'
  }

  def get_status
    STATUS[status]
  end
end
