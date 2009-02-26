class WebUserObserver < ActiveRecord::Observer
  def after_create(web_user)
    WebUserMailer.deliver_signup_notification(web_user)
  end

  def after_save(web_user)
    WebUserMailer.deliver_activation(web_user) if web_user.recently_activated?
    WebUserMailer.deliver_forgot_password(web_user) if web_user.recently_forgot_password?
    WebUserMailer.deliver_reset_password(web_user) if web_user.recently_reset_password?
  end
 

end
