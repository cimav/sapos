class AuditorObserver < ActiveRecord::Observer
   observe :user, :staff

   def after_save(user)
      user2 = User.new
      user.logger.info "COMENT ********************************** #{user} | #{user2}"
   end
end
