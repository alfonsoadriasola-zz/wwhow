require 'net/http'
require 'uri'

class Subscription < ActiveRecord::Base
  belongs_to :user
  def self.get_tweets
    last_twit_id = Subscription.find_by_sql("select max(twit_id) twit_id from blog_entries")[0].twit_id
    http = Net::HTTP.new('twitter.com', 80)
    http.use_ssl = false
    http.start do |h|
      request = Net::HTTP::Get.new("/statuses/replies.json?")
      request.basic_auth('wwhow', 'cheapdeal')
      response = h.request(request)
      @tweets = ActiveSupport::JSON.decode(response.body)
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

  def self.get_price_spider

    response =Net::HTTP.get URI.parse("http://mobi.pricespider.com/Service.svc/GetLocalSellerData?uid=a37267d473ab43d5a9037b9a840fa97c&productId=1297114&geoLocation=37.8118,-122.2553")
    @price_spiders = ActiveSupport::JSON.decode(response)
  end


end
