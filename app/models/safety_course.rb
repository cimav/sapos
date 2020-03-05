class SafetyCourse < ActiveRecord::Base
  attr_accessible :id, :safety_course_type, :name, :email, :score_needed, :score_obtained, :approved, :attachable_type, :attachable_id, :created_at, :updated_at
  belongs_to :attachable, :polymorphic => true

  SEG_LAB  = 1
  BPL      = 2

  TYPE = {
    SEG_LAB => "Seguridad en Laboratorios",
    BPL     => "Buenas Prácticas de Seguridad"
  }
end
