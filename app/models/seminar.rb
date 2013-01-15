class Seminar < ActiveRecord::Base
  attr_accessible :id,:staff_id,:title,:category,:location,:start_date,:end_date,:information,:status,:created_at,:updated_at
  
  ACTIVE  = 1
  DELETED = 2

  STATUS = {
    ACTIVE  => 'Activo',
    DELETED => 'Borrado'
  }

end
