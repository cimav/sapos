# coding: utf-8
class Country < ActiveRecord::Base
  has_many :students, :order => "first_name, last_name"
  has_many :contacts
end
