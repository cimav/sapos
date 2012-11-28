# coding: utf-8
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value=="" 
    else
      unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
        msg_email = I18n.t :email, :scope=>[:activerecord,:errors,:messages]
        record.errors[attribute] << (options[:message] || msg_email )
      end
    end
  end
end

class Student < ActiveRecord::Base
  attr_accessible :id,:program_id,:card,:previous_card,:consecutive,:first_name,:last_name,:gender,:date_of_birth,:city,:state_id,:country_id,:email,:previous_institution,:previous_degree_type,:previous_degree_desc,:previous_degree_date,:contact_id,:start_date,:end_date,:graduation_date,:inactive_date,:supervisor,:co_supervisor,:department_id,:curp,:ife,:cvu,:location,:ssn,:blood_type,:accident_contact,:accident_phone,:passport,:image,:status,:notes,:created_at,:updated_at,:campus_id,:contact_attributes,:scholarship_attributes,:thesis_attributes,:email_cimav,:domain_password,:advance_attributes
  belongs_to :program
  belongs_to :campus

  belongs_to :staff_supervisor, :foreign_key => "supervisor", :class_name => "Staff"
  belongs_to :staff_co_supervisor, :foreign_key => "co_supervisor", :class_name => "Staff"

  belongs_to :state
  belongs_to :country

  has_one :contact, :as => :attachable
  accepts_nested_attributes_for :contact

  has_one :thesis
  accepts_nested_attributes_for :thesis

  has_many :scholarship
  accepts_nested_attributes_for :scholarship

  has_many :advance
  accepts_nested_attributes_for :advance

  has_many :student_file
  accepts_nested_attributes_for :student_file

  has_many :term_students
  accepts_nested_attributes_for :term_students

  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :program_id, :presence => true  
  validates :email_cimav, :email => true, :on => :update
  validates :email, :email => true, :on => :update
  
  after_create :set_card, :add_extra

  mount_uploader :image, StudentImageUploader

  ACTIVE    = 1
  GRADUATED = 2
  INACTIVE  = 3
  UNREGISTERED = 4
  FINISH = 5

  STATUS = {ACTIVE    => 'Activo',
            FINISH => 'Egresado no graduado',
            GRADUATED => 'Graduado',
            INACTIVE  => 'Baja temporal',
            UNREGISTERED  => 'Baja definitiva'
           }

  def status_type
    STATUS[status]
  end
  
  def set_card
    # Update card with format: PPPYYMM999
    # Where:
    #   PPPP is program prefix 
    #   YY Last 2 digits of Year start date
    #   MM Month number of start date
    #   999 Consecutive lead zero
    con = Student.where(:program_id => self.program_id).where("start_date between ? and ?",start_date.strftime('%Y-01-01') ,start_date.strftime('%Y-12-31')).maximum('consecutive')
    if con.nil?
      con = 1
    else 
      con += 1
    end
    consecutive = "%03d" % con
    self.consecutive = con
    self.card = "#{self.program.prefix}#{self.start_date.strftime('%y%m')}#{consecutive}" 
    self.save(:validate => false)
  end
  
  def add_extra
    self.build_contact()
    # self.build_scholarship()
    self.build_thesis()
    self.save(:validate => false)
  end

  def set_nest(item)
    item.student ||= self
  end

  def full_name
    "#{first_name} #{last_name}" rescue ''
  end

  def full_name_by_last
    "#{last_name} #{first_name}" rescue ''
  end

  def full_name_with_card
    "#{card}: #{first_name} #{last_name}" rescue ''
  end

end
