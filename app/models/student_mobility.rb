class StudentMobility < ActiveRecord::Base
  attr_accessible :id,:student_id,:activities,:institution,:start_date,:end_date,:national,:status,:created_at,:updated_at
   	
  ACTIVE  = 1
  DELETED = 2

  STATUS = {
    ACTIVE  => 'Activo',
    DELETED => 'Borrado'
  }

end



