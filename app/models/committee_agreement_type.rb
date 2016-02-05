# coding: utf-8
class CommitteeAgreementType < ActiveRecord::Base
  attr_accessible :id, :description, :authorization, :created_at, :updated_at

  def name
    self.description.force_encoding('UTF-8')
  end
end
