class WebUserMailer < ActionMailer::Base
  def signup_notification(web_user)
    setup_email(web_user)
    @subject    += 'Please activate your new account'
    @body[:url]  = "#{SITE}/activate/#{web_user.activation_code}"

  end

  def activation(web_user)
    setup_email(web_user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "#{SITE}/who/#{web_user.login}"
  end

  def forgot_password(web_user)
    setup_email(web_user)
    @subject =  'You have requested to reset your password'
    @body[:url]  = "#{SITE}/reset_password/#{web_user.password_reset_code}"
  end

  def reset_password(web_user)
    setup_email(web_user)
    @subject= 'Your password has been reset.'

  end

  protected

  def setup_email(web_user)
    @recipients  = "#{web_user.email}"
    @from        = "wwhow"
    @subject     = "WWHOW! "
    @sent_on     = Time.now
    @body[:web_user] = web_user
  end
end
