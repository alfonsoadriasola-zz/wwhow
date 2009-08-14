require 'test_helper'

class SubscriptionsTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test

  end
end


class PriceSpidersTest < SubscriptionsTest
  fixtures :blog_entries

  def setup
    @location = blog_entries(:one)
    @product_list = PriceSpider.get_all_products_list
  end

  def test_price_spiders_product_list
    assert_equal(33, @product_list.size())    
  end

 def test_price_spiders_product_summary
   products = [{:product_id =>1297114}]
   actual = PriceSpider.get_all_product_summary(products)
   assert_equal(actual[0].fetch('Product').fetch('CategoryName'),"LCD TV")   
 end


end
