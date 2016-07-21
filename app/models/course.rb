# coding: utf-8
class Course < ActiveRecord::Base
  attr_accessible :id,:program_id,:code,:name,:lecture_hours,:lab_hours,:credits,:description,:term,:prereq1,:prereq2,:prereq3,:coreq1,:coreq2,:coreq3,:notes,:status,:created_at,:updated_at,:studies_plan_id
  #attr_accesor :full_name_extras
  belongs_to :program
  belongs_to :studies_plan

  has_many :term_courses
  accepts_nested_attributes_for :term_courses

  def full_name
    "#{code}: #{name}" rescue name
  end

  def full_name_extras
    prefix = program.prefix rescue "N.D."
    "#{name} (#{prefix} #{code})"
  end

  def lecture_hours_int
    if lecture_hours.to_s.last(1) == '5'
      lecture_hours
    else 
      lecture_hours.to_i
    end
  end 

  def lab_hours_int
    if lab_hours.to_s.last(1) == '5'
      lab_hours
    else 
      lab_hours.to_i
    end
  end

  def credits_int
    if credits.to_s.last(1) == '5'
      credits
    else 
      credits.to_i
    end
  end
end
