# coding: utf-8
class StudentFile < ActiveRecord::Base
  attr_accessible :id,:student_id,:description,:file,:created_at,:updated_at

  default_scope joins(:student).where('students.deleted=?',0).readonly(false)

  belongs_to :student

  mount_uploader :file, StudentFileUploader

  validates :description, :presence => true
  before_destroy :delete_linked_file

  def delete_linked_file
    self.remove_file!
  end
end
