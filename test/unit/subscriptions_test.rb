require 'test_helper'

class SubscriptionsTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test

  end
end


class PriceSpidersTest < SubscriptionsTest
  fixtures :blog_entries

  def setup
    @location = blog_entries(:three)
    @product_list = PriceSpider.get_all_products_list
    @lcd_tv = {'ProductId' =>1297114}
  end

  def test_price_spiders_product_list
    assert @product_list.size() > 33
  end

  def test_price_spiders_product_summary
    actual = PriceSpider.get_product_summary(@lcd_tv)
    assert_equal(actual[0].fetch('Product').fetch('CategoryName'), "LCD TV")
  end

  def test_get_local_sellers
    actual = PriceSpider.get_local_sellers(@lcd_tv[0], @location)
    assert actual
  end

  def test_should_get_product_summary
    products = []
    @product_list[0..1].each{|p| products << {'ProductId'=> p}}
    result = []
    products.each{|p| result << PriceSpider.get_product_summary(p) }
    assert result
  end

  def test_should_create_lcd_tv_entry
    product = PriceSpider.get_product_summary(@lcd_tv)['Product']
    sellers = PriceSpider.get_local_sellers(product, @location )
    actual = PriceSpider.create_post_by_product_seller(product, sellers)
    assert actual

  end


  def test_should_seed_a_location
     location =  @location 
     PriceSpider.seed_location(location,15)
     actual = User.find_by_name('pricespider').blog_entries.count
     assert actual >= 0
  end

end
