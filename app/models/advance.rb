# coding: utf-8
class Advance < ActiveRecord::Base
  belongs_to :student
  default_scope :order => 'advance_date DESC'
end
