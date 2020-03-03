class GraduatedPoll2020Controller < ApplicationController
  def show_with_token
  	@poll = GraduatedPoll2020.find_by_token(params[:token])
  	render :layout => false
  end

  def update
    @poll =  GraduatedPoll2020.find(params[:id])
    @poll.update_attributes(params[:graduated_poll2020])
    redirect_to '/encuesta/gracias'
  end

  def thanks
  	render :layout => false
  end
end
