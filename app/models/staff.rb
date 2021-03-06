# coding: utf-8
class Staff < ActiveRecord::Base
  attr_accessible :id,:employee_number,:uh_number,:title,:first_name,:last_name,:gender,:date_of_birth,:location,:email,:institution_id,:contact_id,:cvu,:sni,:status,:image,:notes,:created_at,:updated_at,:area_id,:lab_practices_attributes,:seminars_attributes,:external_courses_attributes,:contact_attributes,:staff_type,:admission_exams_attributes, :mobilities_attributes
  belongs_to :institution
  belongs_to :area
  has_many :term_course_schedule
  has_many :teacher_evaluations

  has_many :admission_exams
  accepts_nested_attributes_for :admission_exams

  has_many :seminars
  accepts_nested_attributes_for :seminars

  has_many :mobilities
  accepts_nested_attributes_for :mobilities

  has_many :external_courses
  accepts_nested_attributes_for :external_courses

  has_many :lab_practices
  accepts_nested_attributes_for :lab_practices

  has_many :internships

  has_many :protocols

  has_many :supervised, :class_name => "Student", :foreign_key => :supervisor
  has_many :co_supervised, :class_name => "Student", :foreign_key => :co_supervisor

  has_many :term_courses
  has_many :staff_file
  accepts_nested_attributes_for :staff_file

  has_one :contact, :as => :attachable
  accepts_nested_attributes_for :contact


  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :institution_id, :presence => true

  after_create :add_extra

  mount_uploader :image, StaffImageUploader
  validates      :image, file_content_type: { allow: /^image\/.*/ }

  CIMAV_STAFF = 1
  EXTERNAL = 2
  POSTDOC = 3

  ACTIVE    = 0
  INACTIVE  = 1

  STATUS = {ACTIVE    => 'Activo',
            INACTIVE  => 'Inactivo'}

  TYPES = {CIMAV_STAFF    => 'CIMAV',
            EXTERNAL  => 'Externo',
            POSTDOC => 'Postdoctorado'}


  def get_type
    TYPES[self.staff_type]
  end

  def full_name
    "#{first_name} #{last_name}" rescue ''
  end

  def full_name_by_last
    "#{last_name} #{first_name}" rescue ''
  end

  def full_name_upcase
     self.full_name.mb_chars.upcase rescue ''
  end

  def full_name_upcase_origin
    name_upcase = self.full_name.mb_chars.upcase rescue ''
    origin  = self.institution.short_name

    if self.status.to_i.eql? 1
      return "#{name_upcase} (#{origin}) [INACTIVO]"
    else
      return "#{name_upcase} (#{origin})"
    end
  end

  def full_name_status
    name = self.full_name.mb_chars rescue ''

    if self.status.to_i.eql? 1
      return "#{name} [INACTIVO]"
    else
      return "#{name}"
    end
  end

  def full_name_cap
    new_name = ""
    self.full_name.split(" ").each do |word|
      new_name = "#{new_name} #{word.mb_chars.capitalize}"
    end
    return new_name
  end

  def add_extra
    self.build_contact()
    self.save(:validate => false)
  end

  def active_students
    students = self.supervised.where(:status => Student::ACTIVE) + self.co_supervised.where(:status => Student::ACTIVE)
    active_items = []
    students.each do |s|
      a_s = s
      a_s['program_name'] = s.program.name
      a_s['supervisor_name'] = s.staff_supervisor.full_name
      a_s['co_supervisor_name'] = s.staff_co_supervisor.full_name rescue ''
      active_items << a_s
    end
    active_items
  end

 
   def ggender(option)
    if self.gender == 'F'
      genero   = "a"
      genero2  = "la"
      genero3 = "a la"
    elsif self.gender == 'H'
      genero   = "o"
      genero2  = "el"
      genero3 = "al"
    else
      genero   = "[género no especificado]"
      genero2  = "[género no especificado]"
      genero3 = "[género no especificado]"
    end
    
    if option.eql? "genero"
      return genero
    elsif option.eql? "genero2"
      return genero2
    elsif option.eql? "genero3"
      return genero3
    else
      return "Unknown Option"
    end
  end ##ggender
end
