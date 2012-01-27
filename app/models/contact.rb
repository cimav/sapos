# coding: utf-8
class Contact < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true
  belongs_to :country
  belongs_to :state
end
