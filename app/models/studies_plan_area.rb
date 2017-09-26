class StudiesPlanArea < ActiveRecord::Base
  attr_accessible :id,:studies_plan_id,:name,:created_at,:updated_at

  belongs_to :studies_plan

  validates :studies_plan_id, :presence => true
  validates :name, :presence => true
end
