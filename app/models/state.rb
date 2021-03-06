# coding: utf-8
class State < ActiveRecord::Base
  attr_accessible :id,:name,:code,:created_at,:updated_at, :federal_entity
  has_many :students, :order => "first_name, last_name"
  has_many :contacts
end
