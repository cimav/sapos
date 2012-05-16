class TermStudentPayment < ActiveRecord::Base
  belongs_to :term_student
  
  NONE     = 1 
  PARTIAL  = 2
  TOTAL    = 3

  STATUS = {NONE    => 'Ninguno',
            PARTIAL => 'Parcial',
            TOTAL   => 'Total'}
	
  def status_type
   STATUS[status]
  end
end
