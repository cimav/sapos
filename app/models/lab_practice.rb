class LabPractice < ActiveRecord::Base
  attr_accessible :id,:staff_id,:laboratory_id,:institution_id,:title,:location,:start_date,:end_date,:hours,:participants,:information,:status,:created_at,:updated_at
end
