class BlogEntry < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :what, :message => " - You surely meant to post something"
  validates_length_of   :what,  :within => 3..400

  validates_presence_of :where,  :message => " - did you see this deal? "
  validates_length_of   :where,  :within => 2..400

  validates_presence_of :price, :message => "- How much did you say?"
  validates_numericality_of :price, :message =>" - Please enter numbers only."


  include GeoKit::Geocoders

  acts_as_taggable_on :categories
  acts_as_rateable
  acts_as_mappable   :default_formula => 'radius'

  def set_text_from_attributes
    self.text = %Q{#{self.what} #{self.where} #{self.price} #{self.discount}}
  end

  def set_attributes_from_text
    tokens = self.text.split '#'
    tokens.each{|t| t=t.split}
    self.what = tokens[0].sub('@wwhow', '').downcase
    list = self.what.split(',');
    list.each{|item| self.category_list.concat(item.split(' '))}
    self.where = tokens[1]
    self.price = tokens[2]
    self.discount = tokens[3]
  end

  def set_tags(whats)
    whats.downcase!
    list = whats.split(',');
    list.each do |item|
      item=item.strip;
      if item.size >= 2
        self.category_list.concat(item.split(' '))
      end
    end
  end


  def geocode_where
    if self.where.include?('@')
      address= self.where.split('@')[1]
    else
      address = self.where
    end
    #don't geocode internet address'
    if  address[/^[a-zA-Z0-9\-\.]+\.(com|org|net|mil|edu|COM|ORG|NET|MIL|EDU)$/]!= address then
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


end
