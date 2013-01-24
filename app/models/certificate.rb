class Certificate < ActiveRecord::Base
  attr_accessible :id, :consecutive, :year, :attachable_id, :attachable_type, :type

  belongs_to :attachable, :polymorphic => true
  
  STUDIES    = 1
  ENROLLMENT = 2

  TYPE = {STUDIES => 'Constancia de estudios',
          ENROLLMENT => 'Constancia de inscripcion'
          } 
end
