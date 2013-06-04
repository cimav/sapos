class Applicant < ActiveRecord::Base
  attr_accessible :id,:program_id,:folio,:first_name,:primary_last_name,:second_last_name,:previous_institution,:previous_degree_type,:average,:date_of_birth,:phone,:cell_phone,:email,:address,:civil_status,:created_at,:updated_at,:status,:consecutive,:staff_id, :notes, :campus_id

  belongs_to :program

  after_create :set_folio
  before_create :register

  REGISTERED  = 1
  REJECTED    = 2
  ACCEPTED    = 3
  DELETED     = 4
  
  SINGLE   = 1
  MARRIED  = 2
  DIVORCED = 3

  CIVIL_STATUS = {
    SINGLE => 'Soltero',
    MARRIED => 'Casado',
    DIVORCED => 'Divorciado'   
  }


  STATUS = {
    REGISTERED => 'En Proceso',
    REJECTED   => 'No Aceptado',
    #ACCEPTED   => 'Aceptado',
    DELETED    => 'Borrado'
  }

  belongs_to :program

  validates :first_name, :presence => true
  validates :primary_last_name, :presence => true
  validates :previous_institution, :presence => true
  validates :previous_degree_type, :presence => true
  validates :program_id, :presence => true
  validates :date_of_birth, :presence => true
  validates :notes, :presence => true, :if=> "status.eql? 4" 
  validates :campus_id, :presence => true
  validate :not_repeat_applicant, :on=>:create


  def not_repeat_applicant
    applicants = Applicant.where("first_name=? and primary_last_name=? and second_last_name=? and status = 1",first_name.strip,primary_last_name.strip,second_last_name.strip) 
    
    if applicants.size > 0
      errors.add(:base,"Ya existe un registro activo con ese nombre #{applicants.size}")
    end
  end

  def full_name
    "#{first_name} #{primary_last_name} #{second_last_name}" rescue ''
  end

  def register
    self.status = 1
  end

  def set_folio
    cycle = String.new
    level = String.new
    prefix = String.new
    
    feb = Time.new(Time.now.year,2,1) 
    jul = Time.new(Time.now.year,7,31)
    aug = Time.new(Time.now.year,8,1) 

    if Time.now.month.eql? 1
      jan = Time.new(Time.now.year,1,31)
    else
      jan = Time.new(Time.now.year + 1,1,31)
    end    

    con = Applicant.where("created_at between ? and ?",feb.strftime('%Y-%m-%d') ,jan.strftime('%Y-%m-%d')).maximum('consecutive')
    
    if con.nil?
      con = 1
    else
      con +=1
    end

    if Time.now.between?(feb,jul)
      cycle = "A"     
    else
      cycle = "B"
    end

    consecutive = "%03d" % con
    if self.program
      level  = Program::LEVEL[self.program.level.to_i]
      prefix = self.program.prefix
    else
      level  = "C"
      prefix = "X"
    end

    self.consecutive = con
    self.folio = "C#{level[0]}#{cycle}#{prefix}#{self.created_at.strftime('%Y')}#{consecutive}"
    self.save(:validate => false)
  end
end
