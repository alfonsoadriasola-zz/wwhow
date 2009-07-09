require 'test_helper'

class ApplicationFlowsTest < ActionController::IntegrationTest
  fixtures :web_users, :users, :blog_entries

  def test_should_get_index
    blog_entries(:one).geocode_where
    get  :controller => 'listings;', :action => :index
    assert_response :success
  end

  def test_simplest
    get_via_redirect "/"
    assert_response :success
    assert assigns(:messages)
  end

  def test_should_log_in_and_move_around
    get_via_redirect "/"
    login_as :alfonso
    assert_response :ok
    actual =  assigns(:messages)    
  end

  def test_search
    get_via_redirect "/where/sfo"
    assert_response :success
    assert assigns(:messages)
  end

  def test_far_search
    get_via_redirect "where/jfk"
    assert_response :success
    assert assigns(:messages)
  end

end
