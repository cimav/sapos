class Campus < ActiveRecord::Base
  attr_accessible :id,:short_name,:name,:contact_id,:image,:created_at,:updated_at  

  has_many :students, :order => "first_name, last_name"
  has_many :laboratories
  has_many :user

  has_one :contact, :as => :attachable
  accepts_nested_attributes_for :contact

  validates :name, :presence => true
  validates :short_name, :presence => true

  after_create :add_extra

  mount_uploader :image, CampusImageUploader
  validates      :image, file_content_type: { allow: /^image\/.*/ }

  def full_name
    "#{name} (#{short_name})" rescue ''
  end

  def add_extra
    self.build_contact()
    self.save(:validate => false)
  end

end
