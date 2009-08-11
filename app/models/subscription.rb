require 'net/http'
require 'uri'

class Subscription < ActiveRecord::Base
  belongs_to :user
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


  def self.get_price_spider ( category, location )

    price_spider_categories = [{:product_id => "100162", :description => "Desktops & Workstations"},
                               {:product_id => "100160", :description => "Notebooks & Laptops"},
                               {:product_id => "100099", :description => "Computer and Notebook Memory"},
                               {:product_id => "100104", :description => "Compact Flash"},
                               {:product_id => "100107", :description => "Multimedia Card (mmc)"},
                               {:product_id => "100108", :description => "Memory Stick Pro"},
                               {:product_id => "100109", :description => "Memory Stick Duo"},
                               {:product_id => "100110", :description => "Memory Stick Pro Duo"},
                               {:product_id => "100111", :description => "Memory Stick"},
                               {:product_id => "100112", :description => "MiniSD"},
                               {:product_id => "100113", :description => "Secure Digital SD"},
                               {:product_id => "100115", :description => "xD Picture Card"},
                               {:product_id => "100353", :description => "MicroSD"},
                               {:product_id => "100124", :description => "Hard Drives"},
                               {:product_id => "100148", :description => "LCD TVs"},
                               {:product_id => "100149", :description => "Plasma TVs"},
                               {:product_id => "100007", :description => "MP3 Players"},
                               {:product_id => "100022", :description => "Digital Cameras"},
                               {:product_id => "100513", :description => "35mm & SLR Cameras"},
                               {:product_id => "100261", :description => "Printers"},
                               {:product_id => "100000", :description => "Wireless"},
                               {:product_id => "100038", :description => "Routers / Switches"},
                               {:product_id => "100046", :description => "Network Storage Devices"},
                               {:product_id => "100168", :description => "VPN / Firewall"},
                               {:product_id => "100039", :description => "Printer / Fax servers"},
                               {:product_id => "100305", :description => "Xbox Games"},
                               {:product_id => "100212", :description => "Xbox 360 Games"},
                               {:product_id => "100489", :description => "Playstation 3 Games"},
                               {:product_id => "100854", :description => "Wii Games"},
                               {:product_id => "100293", :description => "PC Games"},
                               {:product_id => "100135", :description => "Projectors"},
                               {:product_id => "100219", :description => "Software"},
                               {:product_id => "100081", :description => "LCD / Flat Panel Displays"}]

    products = price_spider_categories.find_all{|x| x[:description] == "Software"}

    products.each |product|
            begin
              response =Net::HTTP.get URI.parse("http://mobi.pricespider.com/Service.svc/GetLocalSellerData?uid=#{ENV['PRICE_SPIDER_API_KEY']}&productId=#{product_id}&geoLocation=#{location.lat},#{location.lng}")
              @price_spiders = ActiveSupport::JSON.decode(response)

            end



  end


end
