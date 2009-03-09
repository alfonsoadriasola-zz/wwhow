require 'net/http'
require 'uri'

class Subscription < ActiveRecord::Base
  belongs_to :user
  def self.get_twits
    last_twit_id =0
    http = Net::HTTP.new('twitter.com', 80)
    http.use_ssl = false
    http.start do |h|
      request = Net::HTTP::Get.new("/statuses/replies.json?")
      request.basic_auth('wwhow', 'cheapdeal')
      response = h.request(request)
      @twits = ActiveSupport::JSON.decode(response.body)
    end
    return @twits
  end


  def self.create_blog_entries(twits)
    twits.each{|t|
      username = t.fetch('user').fetch('name')
      address = "http://twitter.com/#{username}"
      if user= User.find_by_name( :name => username)
        be = BlogEntry.find_or_create_by_twit_id( :twit_id => t.fetch('id'), :text=>t.fetch('text'), :where=>t.fetch('user').fetch('location'), :user_id => user.id )
        be.set_attributes_from_text
        be.set_tags(be.what)
        be.what = be.what.split(',')[0]
        be.geocode_where
        be.save
      end
    }
  end


end
