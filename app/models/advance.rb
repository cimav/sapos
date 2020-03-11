# coding: utf-8
class Advance < ActiveRecord::Base
  attr_accessible :id,:student_id,:title,:advance_date,:tutor1,:tutor2,:tutor3,:tutor4,:tutor5,:status,:notes,:created_at,:updated_at,:grade1,:grade2,:grade3,:grade4,:grade5,:advance_type
  default_scope joins(:student).where('students.deleted=?',0).readonly(false)
  belongs_to :student

  has_many :protocols
  
  validates :title, :presence=>true, :if=>"advance_type.eql? 3"
  validates :advance_date, :presence=>true, :if=>"advance_type.eql? 3"
  validates :tutor1, :presence=>true, :if=>"advance_type.eql? 3"
  validates :tutor2, :presence=>true, :if=>"advance_type.eql? 3"

  ADVANCE  = 1
  PROTOCOL = 2
  SEMINAR  = 3

  TYPE = {
    ADVANCE   => 'Avance programático',
    PROTOCOL  => 'Evaluación de protocolo',
    SEMINAR   => 'Seminario Departamental',
  }
end
