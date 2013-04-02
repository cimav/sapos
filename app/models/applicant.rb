class Applicant < ActiveRecord::Base
  attr_accessible :id,:program_id,:folio,:first_name,:primary_last_name,:second_last_name,:previous_institution,:previous_degree_type,:average,:date_of_birth,:phone,:cell_phone,:email,:address,:civil_status,:created_at,:updated_at
  
  belongs_to :program

  validates :first_name, :presence => true
  validates :primary_last_name, :presence => true
  validates :previous_institution, :presence => true
  validates :previous_degree_type, :presence => true
  validates :date_of_birth, :presence => true
  
  def full_name
    "#{first_name} #{primary_last_name} #{second_last_name}" rescue ''
  end
end
