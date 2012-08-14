# coding: utf-8
class AcademicDegree < ActiveRecord::Base
  attr_accessible :id,:student_id,:year,:name,:institution_id,:notes,:created_at,:updated_at
end
