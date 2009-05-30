class BlogEntry < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :what, :message => " - You surely meant to post something"
  validates_length_of   :what,  :within => 3..400

  validates_presence_of :where,  :message => " - did you see this deal? "
  validates_length_of   :where,  :within => 2..400

  validates_presence_of :price, :message => "- How much did you say?"
  validates_numericality_of :price, :message =>" - Please enter numbers only."


  include GeoKit::Geocoders
  include ActionView::Helpers::NumberHelper

  acts_as_taggable_on :categories
  acts_as_rateable
  acts_as_mappable   :default_formula => 'radius'

  def set_text_from_attributes
    self.text = %Q{#{self.what} #{self.where} #{self.display_price()} #{self.discount}}
  end

  def set_attributes_from_text
    tokens = self.text.split '#'
    tokens.each{|t| t=t.split}
    self.what = tokens[0].sub('@wwhow', '').downcase
    self.where = tokens[1]
    self.price_text = tokens[2].strip
    self.price = tokens[2].to_f
    set_tags(self.what)
  end

  def set_tags(whats)
    whats.downcase!
    list = whats.split(',');
    list.each do |item|
      item=item.strip;
      self.category_list.concat(item.split(' ').select{|w| w.size > 3 } )
    end
  end


  def geocode_where
    if self.where.include?('@')
      second = self.where.split('@')[1]
      if second
        address= second
      else
        address=self.where
      end
    else
      address = self.where
    end
    #don't geocode internet address'
    cln=String.new
    if  cln=address[/^[a-zA-Z0-9\-\.]+\.(com|org|net|mil|edu|COM|ORG|NET|MIL|EDU)$/].nil? && cln != address then
      loc= MultiGeocoder.geocode(address)
      if loc.success
        self.lat= loc.lat
        self.lng= loc.lng
      else
        self.lat = nil
        self.lng = nil
      end
    end
  end

  def display_price()
    displaytext = String.new
    displaytext = self.price_text.downcase.index(/[aeioubcdfghjklmnpqrstvxxyz]/)  unless self.price_text.nil?||self.price == 0
    if displaytext
      self.price_text
    else
      number_to_currency(self.price)
    end
  end

  def self.get_geolocation(address)
    loc=MultiGeocoder.geocode(address)
    if loc.success
      loc
    end
  end

  def self.trim_tagcloud
    Tag.find(:all).each do |t|
      if t.name.size <= 2
        t.taggings.destroy_all
        t.destroy
      end
    end

  end

  def self.master_category_list
    [' ',
            'Antiques and Hobbies',
            'Clothing and Fashion',
            'Arts and Crafts',
            'Automotive',
            'Baby Gear',
            'Purses, Bags and Luggage',
            'Bridal',
            'Computers and PDAs',
            'Electronics',
            'Eyewear',
            'Food',
            'Freebies',
            'Toys and Games',
            'Flowers and Gifts',
            'Health and Beauty',
            'Home and Garden',
            'Jewelry and watches',
            'Maternity',
            'Movies, Books and Music',
            'Musical Instruments',
            'Office',
            'Cell phones',
            'Photography',
            'Shoes',
            'Sport and Fitness',
            'Wines and Spirits'
    ]
  end


end
