require 'test_helper'

class ListingsControllerTest < ActionController::TestCase
 
  def test_should_get_show
    get :show , {:post_id => 1}
  end

end
