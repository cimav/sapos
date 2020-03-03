class AdmissionExam < ActiveRecord::Base
  belongs_to :staff
  attr_accessible :apply, :exam_date, :make, :review, :status, :staff_id,:id,:created_at,:updated_at

  ACTIVE = 1
  DELETED = 99

end
