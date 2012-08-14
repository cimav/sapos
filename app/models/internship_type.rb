class InternshipType < ActiveRecord::Base
  attr_accessible :id,:name,:created_at,:updated_at
  has_many :internships
  
	validates :name, :presence => true
  
	def full_name
    "#{id}: #{name}" rescue name
  end 
end
