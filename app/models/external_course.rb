class ExternalCourse < ActiveRecord::Base
  attr_accessible :id,:staff_id,:institution_id,:title,:location,:start_date,:end_date,:hours,:participants,:information,:status,:created_at,:updated_at, :course_type

  ACTIVE  = 1
  DELETED = 2

  EXTERNAL_COURSE = 1
  WORKSHOP = 2

  STATUS = {
    ACTIVE  => 'Activo',
    DELETED => 'Borrado'
  }


  TYPES = {
      EXTERNAL_COURSE => 'Curso externo',
      WORKSHOP => 'Taller'
  }

  def get_type
    TYPES[self.course_type]
  end

end
