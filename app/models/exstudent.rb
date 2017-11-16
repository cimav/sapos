class Exstudent < ActiveRecord::Base
  belongs_to :student
  attr_accessible :academic_mobility, :academic_mobility_place, :cellphone, :email, :have_job, :job_chief_name, :job_coincidence, :job_company_name, :job_email, :job_legal_regime, :job_phone, :job_role, :job_studies_impact, :job_type, :phone, :recommendations, :salary, :satisfaction_level, :satisfaction_reason, :scholarship_type, :sni, :study_program_again, :study_program_again_reason, :subsequent_studies

  # Si o no
  YES = true
  NO = false

  # Variables genéricas
  NONE = 0
  OTHER = 10

  # Niveles de SNI
  CANDIDATE = 1
  SNI_1 = 2
  SNI_2 = 3
  SNI_3 = 4

  # Rangos de salarios
  RANGE_1 = 1
  RANGE_2 = 2
  RANGE_3 = 3
  RANGE_4 = 4

  # Grado de satisfacción
  NOT_SATISFIED = 0
  HALF_SATISFIED = 1
  VERY_SATISFIED = 2

  # Tipo de empleo
  OWNER = 1
  PARTNER = 2
  SELF_EMPLOYEE = 3
  EMPLOYEE = 4

  # Tipos de régimen jurídico
  PUBLIC = 1
  PRIVATE = 2

  # Tipos de beca
  CONACYT_SCHOLARSHIP = 1

  # Coincidencia entre estudios y trabajo
  LOW_COINCIDENCE = 1
  MEDIUM_COINCIDENCE =2
  HIGH_COINCIDENCE = 3

  # Impacto de los estudios en su vida laboral
  GOT_BETTER = 1
  THE_SAME = 2
  GOT_WORSE = 3


  JOB_IMPACTS = {
      GOT_BETTER => 'Mejoró',
      THE_SAME => 'Sigue igual',
      GOT_WORSE => 'Empeoró'
  }

  JOB_COINCIDENCES = {
      NONE => 'Ninguna coincidencia',
      LOW_COINCIDENCE => 'Baja coincidencia',
      MEDIUM_COINCIDENCE => 'Mediana coincidencia',
      HIGH_COINCIDENCE => 'Total Coincidencia'
  }

  JOB_LEGAL_TYPES = {
      PUBLIC => 'Público',
      PRIVATE => 'Privado',
      OTHER => 'Otro'
  }

  SHOLARSHIP_TYPES = {
      CONACYT_SCHOLARSHIP => 'Beca CONACYT',
      NONE => 'Ninguna',
      OTHER => 'Otra'
  }

  JOB_TYPES = {
      OWNER => 'Propietario',
      PARTNER => 'Socio',
      SELF_EMPLOYEE => 'Trabajador independiente',
      EMPLOYEE => 'Empleado',
      OTHER => 'Otro'
  }

  SATISFACTION_LEVELS = {
      NOT_SATISFIED => 'Nada satisfecho',
      HALF_SATISFIED => 'Medianamente satisfecho',
      VERY_SATISFIED => 'Totalmente satisfecho'
  }


  SNI_STATUS = {
      NONE        => 'Ninguno',
      CANDIDATE => 'Candidato',
      SNI_1 => 'SNI 1',
      SNI_2 => 'SNI 2',
      SNI_3 => 'SNI 3'
     }

  SALARY_RANGES  = {
      RANGE_1 => '$0 - $10,000',
      RANGE_2 => '$10,000 - $25,000',
      RANGE_3 => '$25,000 - $40,000',
      RANGE_4 => '$40,000+'
  }

end
