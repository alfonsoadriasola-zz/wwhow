require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :redirect    
  end

  def test_should_get_new
    get :new
    assert_response :redirect
  end


  def test_should_show_user
    get :show, :id => users(:one).id
    assert_response :redirect
  end

  def test_should_get_edit
    get :edit, :id => users(:one).id
    assert_response :redirect
  end

  def test_should_update_user
    put :update, :id => users(:one).id, :user => { }
    assert_response :redirect
  end

  def test_should_destroy_user
    login_as :alfonso
    @current_user = users(:one)
    assert_difference('User.count', -1) do
      delete :destroy, :id => users(:two).id
    end

    assert_response :redirect
  end
end
