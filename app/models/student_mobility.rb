class StudentMobility < ActiveRecord::Base
  attr_accessible :id, :student_id, :start_date, :end_date, :staff_id, :place, :institution_id, :activities, :work_title


end
