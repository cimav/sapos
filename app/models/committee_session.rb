# coding: utf-8
class CommitteeSession < ActiveRecord::Base
  attr_accessible :id, :session_type, :status, :created_at, :updated_at, :date
  has_many :committe_session_attendee
  has_many :committe_agreement
  accepts_nested_attributes_for :committe_session_attendee 

  PROGRAMMED = 1
  OPEN       = 2
  CLOSE      = 3

  ORDINARY      = 1
  EXTRAORDINARY = 2

  TYPES = {
    ORDINARY      => 'Ordinaria',
    EXTRAORDINARY => 'Extraordinaria',
  }

  STATUS = {
    PROGRAMMED => 'Programada',
    OPEN       => 'Abierta',
    CLOSE      => 'Finalizada'
  }

  def folio_sup
    if self.session_type.eql? 1
      return "1"
    elsif self.session_type.eql? 2
      return "E"
    else
      return "X"
    end 
  end
end
