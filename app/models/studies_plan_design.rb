class StudiesPlanDesign < ActiveRecord::Base
  attr_accessible :id, :studies_plan_id, :staff_id, :modification_type_id,:design_date,:created_at,:updated_at

  validates :studies_plan_id, :presence => true
  validates :staff_id, :presence => true
  validates :modification_type_id, :presence => true
  validates :design_date, :presence => true

  PLAN_DESIGN = 1
  PROGRAM_DESIGN = 2
  REDESIGN = 3
  PNPC     = 4
  COURSE_CREATION = 5
  COURSE_REDESIGN = 6
  PLAN_REDESING = 7

  MODIFICATION_TYPE = {
    PLAN_DESIGN=>"Diseño de plan de estudios",
    PROGRAM_DESIGN=>"Diseño de plan de programa de estudios",
    REDESIGN=>"Rediseño",
    PNPC    =>"PNPC",
    COURSE_CREATION =>"Creación de Materia",
    COURSE_REDESIGN =>"Rediseño de Materia",
    PLAN_REDESING =>"Rediseño de Plan de Estudios"
  }

end
