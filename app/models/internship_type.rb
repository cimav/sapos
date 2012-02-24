class InternshipType < ActiveRecord::Base
  has_many :internships
  
	validates :name, :presence => true
  
	def full_name
    "#{id}: #{name}" rescue name
  end 
end
