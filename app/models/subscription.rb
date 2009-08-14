require 'net/http'
require 'uri'

class Subscription < ActiveRecord::Base
  belongs_to :user
end

class PriceSpider < Subscription

  def self.get_all_products_list
    products = []
    price_spider_categories = [{:category_id => "100162", :description => "Desktops & Workstations", :category => "Toys"},
                               {:category_id => "100160", :description => "Notebooks & Laptops"},
                               {:category_id => "100099", :description => "Computer and Notebook Memory"},
                               {:category_id => "100104", :description => "Compact Flash"},
                               {:category_id => "100107", :description => "Multimedia Card (mmc)"},
                               {:category_id => "100108", :description => "Memory Stick Pro"},
                               {:category_id => "100109", :description => "Memory Stick Duo"},
                               {:category_id => "100110", :description => "Memory Stick Pro Duo"},
                               {:category_id => "100111", :description => "Memory Stick"},
                               {:category_id => "100112", :description => "MiniSD"},
                               {:category_id => "100113", :description => "Secure Digital SD"},
                               {:category_id => "100115", :description => "xD Picture Card"},
                               {:category_id => "100353", :description => "MicroSD"},
                               {:category_id => "100124", :description => "Hard Drives"},
                               {:category_id => "100148", :description => "LCD TVs"},
                               {:category_id => "100149", :description => "Plasma TVs"},
                               {:category_id => "100007", :description => "MP3 Players"},
                               {:category_id => "100022", :description => "Digital Cameras"},
                               {:category_id => "100513", :description => "35mm & SLR Cameras"},
                               {:category_id => "100261", :description => "Printers"},
                               {:category_id => "100000", :description => "Wireless"},
                               {:category_id => "100038", :description => "Routers / Switches"},
                               {:category_id => "100046", :description => "Network Storage Devices"},
                               {:category_id => "100168", :description => "VPN / Firewall"},
                               {:category_id => "100039", :description => "Printer / Fax servers"},
                               {:category_id => "100305", :description => "Xbox Games"},
                               {:category_id => "100212", :description => "Xbox 360 Games"},
                               {:category_id => "100489", :description => "Playstation 3 Games"},
                               {:category_id => "100854", :description => "Wii Games"},
                               {:category_id => "100293", :description => "PC Games"},
                               {:category_id => "100135", :description => "Projectors"},
                               {:category_id => "100219", :description => "Software"},
                               {:category_id => "100081", :description => "LCD / Flat Panel Displays"}]

    price_spider_categories.each do |category|

      response  = Net::HTTP.get URI.parse("http://mobi.pricespider.com/Service.svc/GetLocalDeals?countryTypeId=1&categoryId=#{category[:category_id]}")
      products << ActiveSupport::JSON.decode(response)

    end
    products
  end

#
#  GetProductSummary
#
#-          Example URL: http://mobi.pricespider.com/Service.svc/GetProductSummary?uid=a37267d473ab43d5a9037b9a840fa97c&productId=1297114
#
#-          Returns details about a given product
#
  def self.get_all_product_summary (products)
    result=[]
    products.each do |product|
      response = Net::HTTP.get URI.parse("http://mobi.pricespider.com/Service.svc/GetProductSummary?uid=a37267d473ab43d5a9037b9a840fa97c&productId=#{product[:product_id]}")
      result << ActiveSupport::JSON.decode(response)
    end
    result
  end

  def self.get_local_product_prices (products, location)

    true
  end


#
#GetSellerData
#
#-          Example URL: http://mobi.pricespider.com/Service.svc/GetSellerData?uid=a37267d473ab43d5a9037b9a840fa97c&productId=1297114
#
#-          Returns all online retailers offering a given product.
#
#
#
#GetLocalSellerData
#
#-          Example URL: http://mobi.pricespider.com/Service.svc/GetLocalSellerData?uid=a37267d473ab43d5a9037b9a840fa97c&productId=1297114&geoLocation=37.8118,-122.2553
#
#-          Returns all local sellers offering a given product. Seller records include records of up to 5 of the closest location local stores near the passed geoLocation coordinates.
#
#
#
#GetProductHistoryData
#
#-          Example URL: http://mobi.pricespider.com/Service.svc/GetProductHistoryData?productId=1297114&lookbackDays=90&aggregateByHour=false
#
#-          Returns the median and lowest prices recorded for the specified number of lookback Days from today
#
#
#
#GetProductSellerHistoryData
#
#-          Example URL: http://mobi.pricespider.com/Service.svc/GetProductSellerHistoryData?productId=1297479&sellerId=194&lookbackDays=90&aggregateByHour=false

  def self.get_price_spider(location)

    get_local_product_prices(get_all_products_list, location)
  end



end

class Twitter < Subscription
  def self.get_tweets
    last_twit_id = Subscription.find_by_sql("select max(twit_id) twit_id from blog_entries")[0].twit_id
    Timeout::timeout(8) do
      begin
        http = Net::HTTP.new('twitter.com', 80)
        http.use_ssl = false
        http.start do |h|
          request = Net::HTTP::Get.new("/statuses/replies.json?")
          request.basic_auth('wwhow', 'cheapdeal')
          response = h.request(request)
          @tweets = ActiveSupport::JSON.decode(response.body)
        end
      rescue
        nil
      end
    end
    return @tweets
  end


  def self.create_blog_entries(tweets)
    tweets.each do|t|
      username = t.fetch('user').fetch('screen_name')
      address =  t.fetch('user').fetch('location')
      if user= User.find_or_create_by_name(username, {:address=> address, :twitter_user => true})
        user.save(false)
        be = BlogEntry.find_or_create_by_twit_id( :twit_id => t.fetch('id'), :text=>t.fetch('text'), :where=>t.fetch('user').fetch('location'), :user_id => user.id )
        if be.lat.nil?
          be.set_attributes_from_text
          be.set_tags_from_what(be.what)
          be.what = be.what.split(',')[0]
          be.geocode_where
          be.save(false)
        end
      end
    end
  end

end
