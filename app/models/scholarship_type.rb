# coding: utf-8
class ScholarshipType < ActiveRecord::Base
  attr_accessible :id,:scholarship_category_id,:name,:description,:created_at,:updated_at
  has_many :scholarship
  belongs_to :scholarship_category
end
