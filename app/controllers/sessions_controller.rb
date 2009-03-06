# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

    layout 'common'

    # Be sure to include AuthenticationSystem in Application Controller instead
    include AuthenticatedSystem

    # render new.rhtml

    def new
    end

    def create
        logout_keeping_session!
        web_user = WebUser.authenticate(params[:login].strip, params[:password].strip)
        if web_user
            # Protects against session fixation attacks, causes request forgery
            # protection if user resubmits an earlier form using back
            # button. Uncomment if you understand the tradeoffs.
            # reset_session
            self.current_web_user = web_user
            new_cookie_flag = (params[:remember_me] == "1")
            handle_remember_cookie! new_cookie_flag
            update_user_rankings                
            redirect_back_or_default("/#{params[:login]}")            
            #flash[:notice] = "Logged in successfully"
        else
            note_failed_signin
            @login       = params[:login]
            @remember_me = params[:remember_me]
            render :action => 'new'
        end
    end

    def destroy
        logout_killing_session!
        flash[:notice] = "You have been logged out."
        redirect_back_or_default('/')
    end

    def update_user_rankings
        users = BlogEntry.find(:all, :select => 'DISTINCT user_id as id', :conditions =>['created_at > ?',Time.now - 60*60*24*180], :limit => 500)        
        users.each{|ur| u= User.find(ur.id); u.rated = User.rate(u); u.ranked = User.rank(u.rated); u.save;}
        current_web_user.user.rated = User.rate(current_web_user.user);
        current_web_user.user.ranked = User.rank(current_web_user.user.rated);
        current_web_user.user.save
    end

    protected
    # Track failed login attempts

    def note_failed_signin
        flash[:error] = "Couldn't log you in as '#{params[:login]}'"
        logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
    end
end
