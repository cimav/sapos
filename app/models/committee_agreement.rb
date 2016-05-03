# coding: utf-8
class CommitteeAgreement < ActiveRecord::Base
  attr_accessible :id, :committee_agreement_type_id, :committee_session_id, :notes, :auth, :created_at, :updated_at
  belongs_to :committee_session
  belongs_to :committee_agreement_type
  has_many :committee_agreement_person, :dependent => :destroy
  has_many :committee_agreement_note, :dependent => :destroy
  has_many :committee_agreement_object, :dependent => :destroy

  YESNO          = 1
  ACADEMIC_STAFF = 2
  PROGRAM        = 3

  AUTH = {
    YESNO          => "Si/No",
    ACADEMIC_STAFF => "Personal Académico",
    PROGRAM        => "Programa"
  }
   
  def get_agreement_number
    agreements = CommitteeAgreement.where(:committee_session_id=>self.committee_session.id).to_a
    return agreements.index(self) + 1 
  end 
end
