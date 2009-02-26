require 'test_helper'

class UserRelationshipsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:user_relationships)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_user_relationship
    assert_difference('UserRelationship.count') do
      post :create, :user_relationship => { }
    end

    assert_redirected_to user_relationship_path(assigns(:user_relationship))
  end

  def test_should_show_user_relationship
    get :show, :id => user_relationships(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => user_relationships(:one).id
    assert_response :success
  end

  def test_should_update_user_relationship
    put :update, :id => user_relationships(:one).id, :user_relationship => { }
    assert_redirected_to user_relationship_path(assigns(:user_relationship))
  end

  def test_should_destroy_user_relationship
    assert_difference('UserRelationship.count', -1) do
      delete :destroy, :id => user_relationships(:one).id
    end

    assert_redirected_to user_relationships_path
  end
end
