class Applicant < ActiveRecord::Base
  attr_accessible :id,:program_id,:folio,:first_name,:primary_last_name,:second_last_name,:previous_institution,:previous_degree_type,:average,:date_of_birth,:phone,:cell_phone,:email,:address,:civil_status,:created_at,:updated_at,:status,:consecutive

  after_create :set_folio
  before_create :register

  REGISTERED  = 1
  REJECTED    = 2
  ACCEPTED    = 3
  DELETED     = 4
  
 STATUS = {
   REGISTERED => 'Registrado',
   REJECTED   => 'Rechazado',
   ACCEPTED   => 'Aceptado',
   DELETED    => 'Borrado'
 }

  belongs_to :program

  validates :first_name, :presence => true
  validates :primary_last_name, :presence => true
  validates :previous_institution, :presence => true
  validates :previous_degree_type, :presence => true
  validates :date_of_birth, :presence => true
  
  def full_name
    "#{first_name} #{primary_last_name} #{second_last_name}" rescue ''
  end

  def register
    self.status = 1
  end

  def set_folio
    con = Applicant.where("created_at between ? and ?",created_at.strftime('%Y-01-01') ,created_at.strftime('%Y-12-31')).maximum('consecutive')
    if con.nil?
      con = 1
    else
      con +=1
    end
    
    consecutive = "%03d" % con
    level       = Program::LEVEL[self.program.level.to_i]
    self.consecutive = con
    self.folio = "C#{level[0]}#{self.created_at.strftime('%Y')}#{consecutive}"
    self.save(:validate => false)
  end
end
