class CommitteeFile < ActiveRecord::Base
  belongs_to :committee_meeting_agreement
  attr_accessible :file, :name
end
