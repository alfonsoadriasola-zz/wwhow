require 'test_helper'

class ListingsControllerTest < ActionController::TestCase
 
  def test_should_get_show
    get :show , {:post_id => 1}
    assert_response :success
  end

  def test_should_get_index
    get :index
    assert_response :ok
  end

end
