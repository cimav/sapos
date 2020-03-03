class StudiesPlan < ActiveRecord::Base
  attr_accessible :id, :program_id, :code, :name, :notes, :status, :created_at, :updated_at, :total_credits

  belongs_to :program

  has_many :studies_plan_area

  validates :code, :presence => true
  validates :name, :presence => true
  

  ACTIVE = 1
  INACTIVE = 2
  DELETED = 99

  STATUS = {ACTIVE   => 'Activo',
            INACTIVE => 'Inactivo',
            DELETED  => 'Borrado'
  }

end
