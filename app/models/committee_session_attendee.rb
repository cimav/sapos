# coding: utf-8
class CommitteeSessionAttendee < ActiveRecord::Base
  attr_accessible :id, :committee_session_id, :staff_id, :department_id, :created_at, :updated_at, :checked
  belongs_to :committee_session
  belongs_to :staff
end
