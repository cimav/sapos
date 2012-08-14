class ActivityLog < ActiveRecord::Base
  attr_accessible :id,:user_id,:activity,:created_at,:updated_at
  belongs_to :user
end
