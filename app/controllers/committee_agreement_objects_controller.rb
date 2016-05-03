# coding: utf-8
class CommitteeAgreementObjectsController < ApplicationController
  before_filter :auth_required
  respond_to :html, :xml, :json

  def index
  end

  def create
    parameters = {}

    @ca_object                        = CommitteeAgreementObject.new
    @ca_object.attachable_type        = params[:attachable_type]
    @ca_object.attachable_id          = params[:attachable_id]
    @ca_object.committee_agreement_id = params[:committee_agreement_id]
    @ca_object.aux                    = params[:aux]

    if @ca_object.save
      render_message(@ca_object,"Alta de sesión exitosa",parameters)
    else
      render_error(@ca_object,"Error al dar de alta la sesión",parameters)
    end
  end
end
