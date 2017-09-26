class StudiesPlanArea < ActiveRecord::Base
  attr_accessible :id,:studies_plan_id,:name,:created_at,:updated_at

  belongs_to :studies_plan
end
