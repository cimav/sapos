# coding: utf-8
class ReportsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
  end
end
