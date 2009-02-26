module AuthenticatedTestHelper
  # Sets the current web_user in the session from the web_user fixtures.
  def login_as(web_user)
    @request.session[:web_user_id] = web_user ? web_users(web_user).id : nil
  end

  def authorize_as(web_user)
    @request.env["HTTP_AUTHORIZATION"] = web_user ? ActionController::HttpAuthentication::Basic.encode_credentials(web_users(web_user).login, 'monkey') : nil
  end
  
end
