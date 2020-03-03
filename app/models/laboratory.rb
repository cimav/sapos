class Laboratory < ActiveRecord::Base
  attr_accessible :id,:campus_id,:code,:name,:created_at,:updated_at
  belongs_to :campus

  validates :name, :presence => true
  validates :code, :presence => true

  def full_name
    "#{code}: #{name}" rescue name
  end

end
