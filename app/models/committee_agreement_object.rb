class CommitteeAgreementObject < ActiveRecord::Base
  attr_accessible :id, :attachable_id, :attachable_type, :committee_agreement_id, :aux
  belongs_to :committee_agreement
  belongs_to :attachable, :polymorphic => true

  validates :attachable_id, :presence=>true
  validates :attachable_type, :presence=>true
  validates :committee_agreement_id, :presence=>true
  validates :aux, :presence=>true, :if=>"attachable_type='Course'"
end
