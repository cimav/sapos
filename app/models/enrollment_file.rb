class EnrollmentFile < ActiveRecord::Base
  attr_accessible :id,:student_id,:term_id,:enrollment_type_id,:description

  mount_uploader :file, EnrollmentFileUploader
 
  belongs_to :term
 
  validates :description, :presence => true
  validates :student_id, :presence => true
  validates :enrollment_type_id, :presence => true
  validates :term_id, :presence => true

  CVU = 1
 
  FILE_TYPE = {
     CVU => "CVU"
   } 
 
 
  def delete_linked_file
    self.remove_file!
  end
end
