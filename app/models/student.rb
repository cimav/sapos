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
  attr_accessible :id,:program_id,:card,:previous_card,:consecutive,:first_name,:last_name,:gender,:date_of_birth,:city,:state_id,:country_id,:email,:previous_institution,:previous_degree_type,:previous_degree_desc,:previous_degree_date,:contact_id,:start_date,:end_date,:graduation_date,:inactive_date,:supervisor,:co_supervisor,:department_id,:curp,:ife,:cvu,:location,:ssn,:blood_type,:accident_contact,:accident_phone,:passport,:image,:status,:notes,:created_at,:updated_at,:campus_id,:contact_attributes,:scholarship_attributes,:thesis_attributes,:email_cimav,:domain_password,:advance_attributes,:deleted,:deleted_at,:studies_plan_id,:external_supervisor,:student_time,:scholarship_type
  
  default_scope where(:deleted=>0)
  
  belongs_to :program
  belongs_to :campus

  belongs_to :staff_supervisor, :foreign_key => "supervisor", :class_name => "Staff"
  belongs_to :staff_co_supervisor, :foreign_key => "co_supervisor", :class_name => "Staff"

  belongs_to :state
  belongs_to :country

  has_one :contact, :as => :attachable
  accepts_nested_attributes_for :contact
  
  has_one :exstudent
  accepts_nested_attributes_for :exstudent

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
  
  has_many :committee_agreement_people, :as=> :attachable
  
  has_many :certificates, :as=> :attachable

  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :campus_id, :presence => true  
  validates :program_id, :presence => true  
  #validates :email_cimav, :email => true, :on => :update
  validates :email, :email => true, :on => :update
  
  after_create :set_card, :add_extra

  mount_uploader :image, StudentImageUploader
  validates      :image, file_content_type: { allow: /^image\/.*/ }

  DELETED      = 0
  ACTIVE       = 1
  GRADUATED    = 2
  INACTIVE     = 3
  UNREGISTERED = 4
  FINISH       = 5
  PENROLLMENT  = 6

  FULL_TIME = 1
  HALF_TIME = 2

  NONE_SCHOLARSHIP = 0
  CONACYT_SCHOLARSHIP = 1
  OTHER_SCHOLARSHIP = 2

  SCHOLARSHIP_TYPES = {
      NONE_SCHOLARSHIP => 'Sin beca',
      CONACYT_SCHOLARSHIP => 'Beca CONACYT',
      OTHER_SCHOLARSHIP => 'Otra'
  }

  STUDENT_TIMES = {
      FULL_TIME => 'Tiempo completo',
      HALF_TIME => 'Medio tiempo'
  }

  STATUS = {
            ACTIVE        => 'Activo',
            FINISH        => 'Egresado no graduado',
            GRADUATED     => 'Graduado',
            INACTIVE      => 'Baja temporal',
            UNREGISTERED  => 'Baja definitiva',
            PENROLLMENT   => 'Pre-inscrito'
           }

  def status_type
    STATUS[self.status]
  end

  def get_scholarship_type
    SCHOLARSHIP_TYPES[self.scholarship_type]
  end

  def get_student_time
    STUDENT_TIMES[self.student_time]
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
  
  def full_name_upcase
     self.full_name.mb_chars.upcase rescue ''
  end

  def full_name_by_last
    "#{last_name} #{first_name}" rescue ''
  end

  def full_name_with_card
    "#{card}: #{first_name} #{last_name}" rescue ''
  end

  def full_name_cap
    new_name = ""
    self.full_name.split(" ").each do |word|
      new_name = "#{new_name} #{word.mb_chars.strip.capitalize}"
    end
    return new_name
  end

  def time_studies
    if thesis.status.eql? "C"
      today = thesis.defence_date
    else
      today = Date.today
    end
    yesterday = start_date
    
    (today.year * 12 + today.month) - (yesterday.year * 12 + yesterday.month)
  end
  
  def get_average
    counter = 0
    counter_grade = 0
    sum = 0
    avg = 0
    self.term_students.each do |te|
      te.term_course_student.where(:status => TermCourseStudent::ACTIVE).each do |tcs|
        counter += 1
        if !(tcs.grade.nil?)
          if !(tcs.grade<70)
            counter_grade += 1
            sum = sum + tcs.grade
          end
        end
      end
    end

    if counter > 0
      avg = (sum / (counter_grade * 1.0)).round(2) if counter_grade > 0
    end
    return avg.to_s
  end

  def get_exstudent_status
    if self.exstudent.nil?
      return nil
    elsif self.exstudent
      return self.exstudent.percentage
    end
  end# get_exstudent_status

  def get_age
    return (Date.today - self.date_of_birth).to_i/365 rescue nil
  end
end
