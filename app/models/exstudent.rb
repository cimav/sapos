# coding: utf-8
class Exstudent < ActiveRecord::Base
  belongs_to :student
  attr_accessible :student_id, :academic_mobility, :academic_mobility_place, :cellphone, :email, :have_job, :job_chief_name, :job_coincidence, :job_company_name, :job_email, :job_legal_regime, :job_phone, :job_role, :job_studies_impact, :job_studies_impact_reason, :job_type, :phone, :recommendations, :salary, :satisfaction_level, :satisfaction_reason, :scholarship_type, :sni, :study_program_again, :study_program_again_reason, :subsequent_studies

  before_save :own_validations

  # Validaciones
  validates :email, :presence => true
  
  # Si o no
  YES = true
  NO = false

  # Variables genéricas
  NONE = 0
  OTHER = 99

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

  SCHOLARSHIP_TYPES = {
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


  def percentage
    sum = 0
    total = 0
    value = 1

    ## 1
    if !self.email.blank?
      sum=sum+value
    end
    total = total + 1
    
    ## 2
    if !self.phone.blank?
      sum=sum+value
    end 
    total = total + 1
    
    ## 3
    if !self.cellphone.blank?
      sum=sum+value
    end 
    total = total + 1
    
    ## 4
    if !self.scholarship_type.blank?
      sum=sum+value
    end 
    total = total + 1

    ## 5
    if !self.subsequent_studies.blank?
      sum=sum+value
    end 
    total = total + 1

    ## 6
    if !self.sni.blank?
      sum=sum+value
    end 
    total = total + 1

    ## 7
    if self.academic_mobility.nil?
      total = total + 1
    else
      sum=sum+value
      if self.academic_mobility
        if !self.academic_mobility_place.blank?
          sum= sum+value
        end
        total = total + 1
      end
    end
    total = total + 1

    ## 9
    if self.have_job.nil?
      total = total + 8
    else
      sum=sum+1
      if self.have_job.eql? true
        ## 10
        if !self.job_type.blank?
          sum=sum+value
        end 
        total = total + 1

        ## 11
        if !self.job_legal_regime.blank?
          sum=sum+value
        end 
        total = total + 1

        ## 12
        if !self.job_company_name.blank?
          sum=sum+value
        end 
        total = total + 1

        ## 13
        if !self.job_role.blank?
          sum=sum+value
        end 
        total = total + 1

        ## 14
        if !self.salary.blank?
          sum=sum+value
        end 
        total = total + 1

        ## 15
        if !self.job_chief_name.blank?
          sum=sum+value
        end 
        total = total + 1

        ## 16
        if !self.job_phone.blank?
          sum=sum+value
        end 
        total = total + 1

        ## 17
        if !self.job_email.blank?
          sum=sum+value
        end 
        total = total + 1
      end#have_job true
    end 
    total = total + 1


    ## 18
    if !self.job_coincidence.blank?
      sum=sum+value
    end 
    total = total + 1

    ## 19
    if !self.job_studies_impact.blank?
      sum=sum+value
    end
    total = total + 1

    ## 20
    if !self.job_studies_impact_reason.blank?
      sum=sum+value
    end 
    total = total + 1

    ## 21
    if !self.recommendations.blank?
      sum=sum+value
    end 
    total = total + 1

    ## 22
    if !self.satisfaction_level.blank?
      sum=sum+value
    end 
    total = total + 1

    ## 23
    if !self.satisfaction_reason.blank?
      sum=sum+value
    end 
    total = total + 1

    ## 24
    if !self.study_program_again.blank?
      sum=sum+value
    end 
    total = total + 1

    ## 25
    if !self.study_program_again_reason.blank?
      sum=sum+value
    end 
    total = total + 1


    percentage = (sum.to_f / total) * 100
    return percentage
    #return percentage.to_i
  end#percentage

private
 
  def own_validations
    errors = 0
    if (self.email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i).nil?
      msg_email = I18n.t :email, :scope=>[:activerecord,:errors,:messages]
      self.errors[:email] << ( msg_email )
      errors = errors + 1
    end

=begin  ## para validar vacíos
    if self.phone.empty?
      msg_phone = "No puede ser vacío"
      self.errors[:phone] << ( msg_phone )
      errors = errors + 1
=end
    if self.phone =~ /\A\s+\z/i
      msg_phone = "No puede dejar espacios en blanco"
      self.errors[:phone] << ( msg_phone )
      errors = errors + 1
    else
      if (self.phone =~ /\A([0-9]+\s*)+\z/i).nil?
        msg_phone = "Solo se permiten números y espacios"
        self.errors[:phone] << ( msg_phone )
        errors = errors + 1
      end
    end
 
    if self.cellphone =~ /\A\s+\z/i
      msg_cellphone = "No puede dejar espacios en blanco"
      self.errors[:cellphone] << ( msg_cellphone )
      errors = errors + 1
    else
      if (self.cellphone =~ /\A([0-9]+\s*)*\z/i).nil?
        msg_cellphone = "Solo se permiten números y espacios"
        self.errors[:cellphone] << ( msg_cellphone )
        errors = errors + 1
      end
    end

    if errors>0
      return false
    else
      return true
    end
  end


end
