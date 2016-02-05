class CommitteeAgreementPerson < ActiveRecord::Base
  attr_accessible :id, :attachable_id, :attachable_type, :committee_agreement_id, :aux
  belongs_to :committee_agreement
  belongs_to :attachable, :polymorphic => true
end
