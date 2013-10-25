class StudentAdvancesFile < ActiveRecord::Base
  attr_accessible :id, :term_student_id,:student_advance_type,:description,:file
  
  default_scope joins(:term_student=>[:student]).where('students.deleted=?',0).readonly(false)
  
  mount_uploader :file, StudentAdvancesFileUploader
  belongs_to :term_student
  validates :description, :presence => true

  SEMESTER = 1
  INTERSEMESTER = 2
  STUDENT_ADVANCE_TYPE  = {
    SEMESTER => "Semestral",
    INTERSEMESTER => "Intersemestral",
  }

  before_destroy :delete_linked_file

  def delete_linked_file
    self.remove_file!
  end
end
