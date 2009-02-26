module AuthenticatedSystem
  protected
    # Returns true or false if the web_user is logged in.
    # Preloads @current_web_user with the web_user model if they're logged in.
    def logged_in?
      !!current_web_user
    end

    # Accesses the current web_user from the session.
    # Future calls avoid the database because nil is not equal to false.
    def current_web_user
      @current_web_user ||= (login_from_session || login_from_basic_auth || login_from_cookie) unless @current_web_user == false
    end

    # Store the given web_user id in the session.
    def current_web_user=(new_web_user)
      session[:web_user_id] = new_web_user ? new_web_user.id : nil
      @current_web_user = new_web_user || false
    end

    # Check if the web_user is authorized
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the web_user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorized?
    #    current_web_user.login != "bob"
    #  end
    #
    def authorized?(action = action_name, resource = nil)
      logged_in?
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def login_required
      authorized? || access_denied
    end

    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the web_user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |format|
        format.html do
          store_location
          redirect_to new_session_path
        end
        # format.any doesn't work in rails version < http://dev.rubyonrails.org/changeset/8987
        # Add any other API formats here.  Some browsers send Accept: */* and 
        # trigger the 'format.any' block incorrectly.
        format.any(:json, :xml) do
          request_http_basic_authentication 'Web Password'
        end
      end
    end
   
    def access_denied
     respond_to do |accepts|
        accepts.html do
          store_location
          redirect_to new_session_path
        end
        accepts.js do
          render(:update) { |page| page.redirect_to new_session_path }
        end
        accepts.xml do
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render :text => "Could't authenticate you", :status => '401 Unauthorized'
        end
      end
      false
    end


    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.request_uri
    end

    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.  Set an appropriately modified
    #   after_filter :store_location, :only => [:index, :new, :show, :edit]
    # for any controller you want to be bounce-backable.
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    # Inclusion hook to make #current_web_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_web_user, :logged_in?, :authorized? if base.respond_to? :helper_method
    end

    #
    # Login
    #

    # Called from #current_web_user.  First attempt to login by the web_user id stored in the session.
    def login_from_session
      self.current_web_user = WebUser.find_by_id(session[:web_user_id]) if session[:web_user_id]
    end

    # Called from #current_web_user.  Now, attempt to login by basic authentication information.
    def login_from_basic_auth
      authenticate_with_http_basic do |login, password|
        self.current_web_user = WebUser.authenticate(login, password)
      end
    end
    
    #
    # Logout
    #

    # Called from #current_web_user.  Finaly, attempt to login by an expiring token in the cookie.
    # for the paranoid: we _should_ be storing web_user_token = hash(cookie_token, request IP)
    def login_from_cookie
      web_user = cookies[:auth_token] && WebUser.find_by_remember_token(cookies[:auth_token])
      if web_user && web_user.remember_token?
        self.current_web_user = web_user
        handle_remember_cookie! false # freshen cookie token (keeping date)
        self.current_web_user
      end
    end

    # This is ususally what you want; resetting the session willy-nilly wreaks
    # havoc with forgery protection, and is only strictly necessary on login.
    # However, **all session state variables should be unset here**.
    def logout_keeping_session!
      # Kill server-side auth cookie
      @current_web_user.forget_me if @current_web_user.is_a? WebUser
      @current_web_user = false     # not logged in, and don't do it for me
      kill_remember_cookie!     # Kill client-side auth cookie
      session[:web_user_id] = nil   # keeps the session but kill our variable
      # explicitly kill any other session variables you set
    end

    # The session should only be reset at the tail end of a form POST --
    # otherwise the request forgery protection fails. It's only really necessary
    # when you cross quarantine (logged-out to logged-in).
    def logout_killing_session!
      logout_keeping_session!
      reset_session
    end
    
    #
    # Remember_me Tokens
    #
    # Cookies shouldn't be allowed to persist past their freshness date,
    # and they should be changed at each login

    # Cookies shouldn't be allowed to persist past their freshness date,
    # and they should be changed at each login

    def valid_remember_cookie?
      return nil unless @current_web_user
      (@current_web_user.remember_token?) && 
        (cookies[:auth_token] == @current_web_user.remember_token)
    end
    
    # Refresh the cookie auth token if it exists, create it otherwise
    def handle_remember_cookie!(new_cookie_flag)
      return unless @current_web_user
      case
      when valid_remember_cookie? then @current_web_user.refresh_token # keeping same expiry date
      when new_cookie_flag        then @current_web_user.remember_me 
      else                             @current_web_user.forget_me
      end
      send_remember_cookie!
    end
  
    def kill_remember_cookie!
      cookies.delete :auth_token
    end
    
    def send_remember_cookie!
      cookies[:auth_token] = {
        :value   => @current_web_user.remember_token,
        :expires => @current_web_user.remember_token_expires_at }
    end

end
