# coding: utf-8
class Department < ActiveRecord::Base
  attr_accessible :id,:name,:description,:created_at,:updated_at
  validates :name, :presence => true
  validates :description, :presence => true

  def full_name
    "#{id}: #{name}" rescue name
  end 
end
