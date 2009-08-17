class Twitter < Subscription

  def self.get_tweets
    last_twit_id = Twitter.find_by_sql("select max(twit_id) twit_id from blog_entries")[0].twit_id
    Timeout::timeout(8) do
      begin
        http = Net::HTTP.new('twitter.com', 80)
        http.use_ssl = false
        http.start do |h|
          request = Net::HTTP::Get.new("/statuses/mentions.json?since_id=#{last_twit_id}")
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
      if user= User.find_by_name(username, {:address=> address, :twitter_user => true})
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