# coding: utf-8
class Contact < ActiveRecord::Base
  attr_accessible :id,:attachable_id,:attachable_type,:address1,:address2,:city,:state_id,:zip,:country_id,:mobile_phone,:home_phone,:work_phone,:website,:lat,:long,:created_at,:updated_at
  belongs_to :attachable, :polymorphic => true
  belongs_to :country
  belongs_to :state
end
