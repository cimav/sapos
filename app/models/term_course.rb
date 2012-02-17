# coding: utf-8
class TermCourse < ActiveRecord::Base
  belongs_to :term
  belongs_to :course
  belongs_to :staff

  has_many :term_course_schedules
  accepts_nested_attributes_for :term_course_schedules

  has_many :term_course_students
  accepts_nested_attributes_for :term_course_students

  ASSIGNED   = 1
  UNASSIGNED = 2

  after_create :set_group

  def set_group
    g = TermCourse.where(:term_id => self.term_id).where(:course_id => self.course_id).maximum('group')
    if g.nil?
      g = 'A'
    else
      g = g.next
    end
    self.group = g
    self.save
  end

end
