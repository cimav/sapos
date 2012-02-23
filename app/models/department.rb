# coding: utf-8
class Department < ActiveRecord::Base
  validates :name, :presence => true
  validates :description, :presence => true

  def full_name
    "#{id}: #{name}" rescue name
  end 
end
