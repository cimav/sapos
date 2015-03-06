class Internship < ActiveRecord::Base
  attr_accessible :id,:internship_type_id,:first_name,:last_name,:gender,:date_of_birth,:start_date,:end_date,:location,:email,:institution_id,:contact_id,:staff_id,:thesis_title,:activities,:status,:image,:notes,:created_at,:updated_at,:blood_type,:campus_id,:contact_attributes,:career,:office,:total_hours,:schedule, :control_number, :grade, :applicant_status
  attr_accessible  :area_id, :country_id, :state_id

  belongs_to :institution
  belongs_to :staff
  belongs_to :internship_type

  has_one :contact, :as => :attachable
  accepts_nested_attributes_for :contact

  has_many :internship_file
  accepts_nested_attributes_for :internship_file

  validates :first_name, :presence => true, :uniqueness=>{:scope=>[:last_name,:institution_id,:internship_type_id,:gender]}
  validates :last_name, :presence => true, :uniqueness=>{:scope=>[:first_name,:institution_id,:internship_type_id,:gender]}
  validates :institution_id, :presence => true
  validates :internship_type_id, :presence => true
  validates :gender, :presence => true
  validates :date_of_birth, :presence => true
  validates :country_id, :presence => true
  validates :state_id, :presence => true
  validates :area_id, :presence => true

  after_create :add_extra

  mount_uploader :image, InternshipImageUploader

  ACTIVE    = 0
  FINISHED  = 1
  INACTIVE  = 2
  APPLICANT = 3

  STATUS = {ACTIVE    => 'Activo',
            FINISHED  => 'Finalizado',
            INACTIVE  => 'Inactivo',
            APPLICANT => 'Aspirante'}


  ACCEPTED = 1
  REJECTED = 2

  APPLICANT_STATUS = { ACTIVE    => 'Activo',
                       REJECTED  => 'Rechazado',
                       ACCEPTED  => 'Aceptado'
                      }

  def full_name
    "#{first_name} #{last_name}" rescue ''
  end

  def add_extra
    self.build_contact()
    self.save(:validate => false)
  end

end
