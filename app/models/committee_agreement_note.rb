class CommitteeAgreementNote < ActiveRecord::Base
  attr_accessible :id, :committee_agreement_id, :notes
  belongs_to :committee_agreement
end
