# coding: utf-8
class State < ActiveRecord::Base
  has_many :students, :order => "first_name, last_name"
  has_many :contacts
end
