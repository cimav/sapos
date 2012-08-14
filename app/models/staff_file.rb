class StaffFile < ActiveRecord::Base
  attr_accessible :id,:staff_id,:description,:file,:created_at,:updated_at
  mount_uploader :file, StaffFileUploader
  validates :description, :presence => true

  before_destroy :delete_linked_file

  def delete_linked_file
    self.remove_file!
  end
end
