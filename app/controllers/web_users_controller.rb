class WebUsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead

  layout 'common'

  # render new.rhtml

  def new
    @web_user = WebUser.new
  end

  def show
    @web_user = WebUser.find_by_id(params[:id])
    redirect_to "/#{@web_user.user.name}"
  end


  def create
    logout_keeping_session!
    @web_user = WebUser.new(params[:web_user])
    success = verify_recaptcha(@web_user) if @web_user
    if success && @web_user.save
      if @web_user.create_user(:name=>@web_user.login, :uri => @web_user.email, :address => params[:web_user][:address])
        redirect_to :action => 'activate', :activation_code => @web_user.activation_code
      else
        render :action => 'new'
      end
    else
      render :action => 'new'
    end

  end

  def activate
    logout_keeping_session!
    web_user = WebUser.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && web_user && !web_user.active?
      web_user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/login')
    else
      flash[:error]  = "We couldn't find a web_user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/login')
    end
  end

  def forgot_password
    if request.post?
      @web_user = WebUser.find_by_email(params[:web_user][:email].strip)
      if @web_user
        @web_user.forgot_password
        flash[:notice] = "Reset code sent to #{@web_user.email}"
        render :action => 'after_forgot_password'
      else
        flash[:error] = "#{params[:web_user][:email]} does not exist in system"
        redirect_back_or_default('/forgot_password')
      end

    end
  end

  def reset_password
    @web_user = WebUser.find_by_password_reset_code(params[:code]) unless params[:code].nil?
    if request.post?
      if @web_user.update_attributes(:password => params[:web_user][:password], :password_confirmation => params[:web_user][:password_confirmation])
        self.current_web_user = @web_user
        @web_user.delete_password_code
        flash[:notice] = "Password reset successfully for #{@web_user.email}"
        redirect_back_or_default("/#{@web_user.login}")
      else
        render :action => :reset_password
      end
    end
  end

end
