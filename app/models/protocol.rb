# coding: utf-8
class Protocol < ActiveRecord::Base
  attr_accessible :id,:advance_id,:staff_id,:group,:grade,:created_at,:updated_at

  belongs_to :staffs
  belongs_to :students

  has_many :answers
end
