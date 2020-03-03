class CommitteeMeetingAgreementsController < ApplicationController
  respond_to :html, :xml, :json
  before_filter :auth_required
  def index
    @meetings = CommitteeMeeting.all
  end
  def new
    @meeting_agreement = CommitteeMeetingAgreement.new
    render :layout =>false
  end
  def live_search
    @meeting_agreements = CommitteeMeetingAgreement.where(:committee_meeting_id => params[:sesion])
    @selected_meeting = params[:sesion]
    render :layout => false
  end
  def show
    @meeting_agreement = CommitteeMeetingAgreement.find(params[:id])
    render :layout =>false
  end

  def create
    parameters = {}
    @meeting_agreement = CommitteeMeetingAgreement.new()
    @meeting_agreement.description = params[:committee_meeting_agreement][:description]
    @meeting_agreement.agreement_type = params[:committee_meeting_agreement][:agreement_type]
    @meeting_agreement.committee_meeting_id = params[:committee_meeting_id]
    if @meeting_agreement.save
      render_message(@meeting_agreement,"Se creó un nuevo acuerdo",parameters)
    else
      render_error(@meeting_agreement,"Error al guardar el acuerdo",parameters)
    end
  end

  def update
    parameters = {}
    @meeting_agreement = CommitteeMeetingAgreement.find(params[:id])
    @meeting_agreement.description = params[:committee_meeting_agreement][:description]
    @meeting_agreement.agreement_type = params[:committee_meeting_agreement][:agreement_type]
    if @meeting_agreement.save
      render_message(@meeting_agreement,"Se ha guardado el acuerdo",parameters)
    else
      render_error(@meeting_agreement,"Error al guardar el acuerdo",parameters)
    end
  end
end
