class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "is not an email")
    end
  end
end

class Applicant < ActiveRecord::Base
  attr_accessible :id,:program_id,:folio,:first_name,:primary_last_name,:second_last_name,:previous_institution,:previous_degree_type,:average,:date_of_birth,:phone,:cell_phone,:email,:address,:civil_status,:created_at,:updated_at,:status,:consecutive,:staff_id, :notes, :campus_id, :student_id,:place_id,:password,:curp,:country_id

  belongs_to :program
  belongs_to :campus
  belongs_to :country

  after_create :set_folio
  #before_create :register

  validates :country_id, :presence => true
  validates :curp, :format => { :with => /^([A-Z][AEIOUX][A-Z]{2}\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])[HM](?:AS|B[CS]|C[CLMSH]|D[FG]|G[TR]|HG|JC|M[CNS]|N[ETL]|OC|PL|Q[TR]|S[PLR]|T[CSL]|VZ|YN|ZS)[B-DF-HJ-NP-TV-Z]{3}[A-Z\d])(\d)$/, :message => "Formato incorrecto" },:presence=>true,:if=>"self.country_id.eql? 146"

  REGISTERED    = 1
  REJECTED      = 2
  ACCEPTED      = 3
  DELETED       = 4
  ACCEPTED_PROP = 5
  DESISTS       = 6
  REQUEST_PASS  = 7
  REQUEST       = 8
  
  SINGLE   = 1
  MARRIED  = 2
  DIVORCED = 3

  CIVIL_STATUS = {
    SINGLE => 'Soltero',
    MARRIED => 'Casado',
    DIVORCED => 'Divorciado'   
  }


  STATUS = {
    REGISTERED    => 'En Proceso',
    REJECTED      => 'No Aceptado',
    ACCEPTED      => 'Aceptado',
    ACCEPTED_PROP => 'Aceptado a propedeutico',
    DELETED       => 'Borrado',
    DESISTS       => 'Desiste',
    REQUEST_PASS  => 'Solicitud de password',
    REQUEST       => 'Solicitud',
  }

  CUU = 1
  MTY = 2
  DGO = 3
  TIJ = 4
  CUL = 5
  HMO = 6
  GDL = 7
  QRO = 8
  XAL = 9
  MID = 10
  MEX = 11

  PLACES = {
    CUU => "Chihuahua",
    MTY => "Monterrey",
    DGO => "Durango",
    TIJ => "Tijuana",
    CUL => "Culiacán",
    HMO => "Hermosillo",
    GDL => "Guadalajara",
    QRO => "Querétaro",
    XAL => "Jalapa",
    MID => "Mérida",
    MEX => "Ciudad de México",
  }

  belongs_to :program

  validates :first_name, :presence => true, :if=>"status.in? [1,2,3,4,5,6,7,8]"
  validates :primary_last_name, :presence => true, :if=>"status.in? [1,2,3,4,5,6,7,8]"
  validates :previous_institution, :presence => true, :if=>"status.in? [1,2,3,4,5,6,8]"
  validates :previous_degree_type, :presence => true, :if=>"status.in? [1,2,3,4,5,6,8]"
  validates :program_id, :presence => true, :if=>"status.in? [1,2,3,4,5,6,7,8]"
  validates :date_of_birth, :presence => true, :if=>"status.in? [1,2,3,4,5,6,8]"
  validates :notes, :presence => true, :if=> "status.eql? 4" 
  validates :staff_id, :presence => true, :if=>"status.in? [1,2,3,4,5,6,8] and program_id.to_i.in? [2,4,10]"
  validates :campus_id, :presence => true, :if=>"status.in? [1,2,3,4,5,6,7,8]"
  validates :civil_status, :presence => true, :if=> "status.eql? 8"
  validates :phone, :presence => true, :if=> "status.eql? 8"
  validates :cell_phone, :presence => true, :if=> "status.eql? 8"
  validates :email, :presence => true, :email=>true, :if=> "status.in? [7,8]"
  validates :address, :presence => true, :if=> "status.eql? 8"
  validate :not_repeat_applicant, :on=>:create


  def not_repeat_applicant
    applicants = Applicant.where("first_name=? AND primary_last_name=? AND second_last_name=? AND program_id=? AND status in (1,3,5,7)",first_name.strip,primary_last_name.strip,second_last_name.strip,program_id) 
    
    if applicants.size > 0
      errors.add(:base,"0x0 Ya existe un registro activo con ese nombre #{applicants.size}")
    end
  end

  def full_name
    "#{first_name} #{primary_last_name} #{second_last_name}" rescue ''
  end

  #def register
  #  self.status = 1
  #end

  def create_folio
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
    folio = "C#{level[0]}#{cycle}#{prefix}#{self.created_at.strftime('%Y')}#{consecutive}"
    return folio
  end 

  def set_folio
    self.folio = self.create_folio
    self.save(:validate => false)
  end
   
  def update_folio
    self.folio = self.create_folio
  end

protected
  def campus_valid? 
    ([2,4,10].include? self.program_id.to_i)
  end


end
