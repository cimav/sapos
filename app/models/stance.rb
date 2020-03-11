# coding: utf-8
class Stance < ActiveRecord::Base
  attr_accessible :id,:student_id,:institution_id,:start_date,:end_date,:agreement,:status,:notes,:created_at,:updated_at
end
