class User < ActiveRecord::Base

  has_many  :blog_entries
  has_many  :subscriptions
  belongs_to :web_user

  acts_as_mappable :auto_geocode => true
  before_validation_on_update :geocode_address

  validates_uniqueness_of  :name

  def self.find_active
    User.find(:all, :conditions => ['rated > 0'], :order => "rated desc", :limit => 50 )
  end

  private
  def self.rate(user)

    entries = user.blog_entries.count
    ratedMessags, messagesRated, averageRating = 0
    ratedMessages = Rating.count(:conditions => [ %Q{rateable_type='BlogEntry'
                                 and rateable_id in
                                        (select b.id
                                        from  blog_entries b
                                        where b.user_id = ? ) }, user.id ] )

    messagesRated = Rating.count(:conditions =>[ "user_id = ?",user.id])
    averageRating = Rating.average(:rating, :conditions => [ %Q{rateable_type='BlogEntry'
                                 and rateable_id in
                                        (select b.id
                                        from  blog_entries b
                                        where b.user_id = ? ) }, user.id ] )

    ratedMessages = 1 if ratedMessages.nil?
    messagesRated = 1 if messagesRated.nil?
    averageRating = 1 if averageRating.nil?

    averageRating  * (entries*2 + ratedMessages * 2  + messagesRated )
  end

  def self.rank(rating)
    case rating
    when 0..169
      "got a bit"
    when 170..399
      "got some"
    when 400..899
      "pretty good"
    when 900..1599
      "darn good"
    when 1600..2799
      "really great"
    when 2800..3600
      "wwhow!"
    else
      "wwhow!!!"
    end

  end

  def self.update_all_users_ranking
    users = User.find(:all)
    users.each{|ur| u= User.find(ur.id); u.rated = User.rate(u); u.ranked = User.rank(u.rated); u.save;}
  end

  private

  def geocode_address
    if address.blank?
      self.lat = nil
      self.lng = nil
    else
      geo=GeoKit::Geocoders::MultiGeocoder.geocode(address)
      errors.add(:address, "Could not Geocode address") unless geo.success
      self.lat, self.lng = geo.lat, geo.lng if geo.success
    end
  end

  def show_unmapped

  end

end