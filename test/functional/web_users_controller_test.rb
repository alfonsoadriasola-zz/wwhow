require File.dirname(__FILE__) + '/../test_helper'
require 'web_users_controller'

# Re-raise errors caught by the controller.
class WebUsersController; def rescue_action(e) raise e end; end

class WebUsersControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :web_users

  def test_should_allow_signup
    assert_difference 'WebUser.count' do
      create_web_user
      assert_response :redirect
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference 'WebUser.count' do
      create_web_user(:login => nil)
      assert assigns(:web_user).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference 'WebUser.count' do
      create_web_user(:password => nil)
      assert assigns(:web_user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'WebUser.count' do
      create_web_user(:password_confirmation => nil)
      assert assigns(:web_user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference 'WebUser.count' do
      create_web_user(:email => nil)
      assert assigns(:web_user).errors.on(:email)
      assert_response :success
    end
  end
  

  
  def test_should_sign_up_user_with_activation_code
    create_web_user
    assigns(:web_user).reload
    assert_not_nil assigns(:web_user).activation_code
  end

  def test_should_activate_user
    assert_nil WebUser.authenticate('aaron', 'test')
    get :activate, :activation_code => web_users(:aaron).activation_code
    assert_redirected_to '/session/new'
    assert_not_nil flash[:notice]
    assert_equal web_users(:aaron), WebUser.authenticate('aaron', 'monkey')
  end
  
  def test_should_not_activate_user_without_key
    get :activate
    assert_nil flash[:notice]
  rescue ActionController::RoutingError
    # in the event your routes deny this, we'll just bow out gracefully.
  end

  def test_should_not_activate_user_with_blank_key
    get :activate, :activation_code => ''
    assert_nil flash[:notice]
  rescue ActionController::RoutingError
    # well played, sir
  end

  protected
    def create_web_user(options = {})
      post :create, :web_user => { :login => 'quire', :email => 'quire@example.com',
        :password => 'quire69', :password_confirmation => 'quire69' }.merge(options)
    end
end
