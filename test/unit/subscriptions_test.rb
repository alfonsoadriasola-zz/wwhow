require 'test_helper'

class SubscriptionsTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_price_spider
    ps = Subscription.get_price_spider
    assert ps
  end
  
end
