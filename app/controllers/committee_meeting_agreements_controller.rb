class CommitteeMeetingAgreementsController < ApplicationController
  def index
    @meetings = CommitteeMeeting.all
  end
  def new
    @meeting_agreement = CommitteeMeetingAgreement.new
    render :layout =>false
  end
  def live_search
    @meeting_agreements = CommitteeMeetingAgreement.where(:committee_meeting_id => params[:sesion])
    render :layout => false
  end
  def show
    @meeting_agreement = CommitteeMeetingAgreement.find(params[:id])
    render :layout =>false
  end
end
