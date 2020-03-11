# coding: utf-8
class Country < ActiveRecord::Base
  attr_accessible :id,:name,:code,:created_at,:updated_at
  has_many :students, :order => "first_name, last_name"
  has_many :contacts
end
