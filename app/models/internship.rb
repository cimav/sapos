class Internship < ActiveRecord::Base
  attr_accessible :id,:internship_type_id,:curp,:first_name,:last_name,:gender,:date_of_birth,:start_date,:end_date,:location,:email,:institution_id,:contact_id,:staff_id,:thesis_title,:activities,:status,:image,:notes,:created_at,:updated_at,:blood_type,:campus_id,:contact_attributes,:career,:office,:total_hours,:schedule, :control_number, :grade, :applicant_status, :area_id, :country_id, :state_id, :phone, :health_insurance, :health_insurance_number,:accident_contact, :chosen_campus
 
  belongs_to :institution
  belongs_to :staff
  belongs_to :internship_type
  belongs_to :area

  has_one :contact, :as => :attachable
  accepts_nested_attributes_for :contact

  has_many :internship_file
  accepts_nested_attributes_for :internship_file

  validates :first_name, :presence => true#, :uniqueness=>{:scope=>[:last_name,:institution_id,:internship_type_id,:gender,:status]}
  validates :last_name, :presence => true#, :uniqueness=>{:scope=>[:first_name,:institution_id,:internship_type_id,:gender,:status]}
  validates :institution_id,:presence => true,:if=>"self.origin.eql? 0"
  validates :internship_type_id, :presence => true
  validates :gender, :presence => true
  validates :date_of_birth, :presence => true
  #validates :country_id, :presence => true
  #validates :state_id, :presence => true
  validates :area_id, :presence => true
  validates :curp, :presence => true
  validates :curp, :format => { :with => /^([A-Z][AEIOUX][A-Z]{2}\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])[HM](?:AS|B[CS]|C[CLMSH]|D[FG]|G[TR]|HG|JC|M[CNS]|N[ETL]|OC|PL|Q[TR]|S[PLR]|T[CSL]|VZ|YN|ZS)[B-DF-HJ-NP-TV-Z]{3}[A-Z\d])(\d)$/, :message => "Formato incorrecto" }
  validates :phone, :presence => true,:if=>"self.origin.eql? 0"
  validates :health_insurance, :presence => true,:if=>"self.origin.eql? 0"
  validates :health_insurance_number, :presence => true,:if=>"self.origin.eql? 0"
  validates :accident_contact, :presence => true,:if=>"self.origin.eql? 0"
  #validate_with StartVsCreated, :fields=> [:origin, :status, :applicant_status]
  validate :start_date_vs_created_at, :on=>:update
  #validate :start_date_vs_created_at, :if=>"((self.origin.eql? 0) && (self.status.eql? 3) && (self.applicant_status.in? [1,3,4]))", :on=>:update
  #validate :start_date_vs_created_at, :if=>"((self.origin.eql? 0) && (self.status.eql? 3) && (self.applicant_status.in? [1,3,4]))", :on=>:update

  after_create :add_extra

  mount_uploader :image, InternshipImageUploader
  validates      :image, file_content_type: { allow: /^image\/.*/ }

  ACTIVE    = 0
  FINISHED  = 1
  INACTIVE  = 2
  APPLICANT = 3

  STATUS = {ACTIVE    => 'Activo',
            FINISHED  => 'Finalizado',
            INACTIVE  => 'Inactivo',
            APPLICANT => 'Aspirante'}


  ACCEPTED   = 1
  REJECTED   = 2
  AUTHORIZED = 3
  INTERVIEW  = 4
  PENDING    = 99

  APPLICANT_STATUS = { 
                       ACTIVE    => 'Activo',
                       REJECTED  => 'Rechazado',
                       ACCEPTED  => 'Aceptado',
                       AUTHORIZED => 'Autorizado',
                       INTERVIEW  => 'Entrevista',
                       PENDING    => 'Pendiente'      
                      }

  def full_name
    "#{first_name} #{last_name}" rescue ''
  end

  def full_name_cap
    new_name = ""
    self.full_name.split(" ").each do |word|
      new_name = "#{new_name} #{word.mb_chars.strip.capitalize}"
    end
    return new_name
  end

  def add_extra
    self.build_contact()
    self.save(:validate => false)
  end

  def origin=(data)
    @origin=data
  end

  def origin
    @origin || 0
  end

  def start_date_vs_created_at
    if ((self.origin.eql? 0) && (self.status.eql? 3) && (self.applicant_status.in? [1,3]))
      created_at_1 = Date.new(self.created_at.year,self.created_at.month,self.created_at.day)
      if self.start_date.to_datetime<created_at_1
        errors.add(:start_date,"La fecha de inicio no puede ser menor a la fecha de registro")
      end
    end
  end #def start_date_vs_created_at

end # class  Internship

