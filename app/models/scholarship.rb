# coding: utf-8
class Scholarship < ActiveRecord::Base
  attr_accessible :id,:student_id,:start_date,:end_date,:status,:notes,:created_at,:updated_at,:scholarship_type_id,:amount,:institution_id,:department_id,:other_department,:scholarship_types_attributes
  belongs_to :student
  belongs_to :scholarship_type

  validates :student_id, :presence => true
  validates :scholarship_type_id, :presence => true
  validates :amount, :presence => true
  validates :start_date, :presence => true
  validates :end_date, :presence => true
  validates :status, :presence => true
end
