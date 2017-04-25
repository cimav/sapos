class CommitteeMeetingsController < ApplicationController
  def index
  end

  def new
    @committee_meeting = CommitteeMeeting.new
  end
  
  def create
    
  end
end
