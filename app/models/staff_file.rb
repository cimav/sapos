class StaffFile < ActiveRecord::Base
  mount_uploader :file, StaffFileUploader
  validates :description, :presence => true

  before_destroy :delete_linked_file

  def delete_linked_file
    self.remove_file!
  end
end
