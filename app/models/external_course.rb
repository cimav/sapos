class ExternalCourse < ActiveRecord::Base
  attr_accessible :id,:staff_id,:institution_id,:title,:location,:start_date,:end_date,:hours,:participants,:information,:status,:created_at,:updated_at
  ACTIVE  = 1
  DELETED = 2

  STATUS = {
    ACTIVE  => 'Activo',
    DELETED => 'Borrado'
  }
end
