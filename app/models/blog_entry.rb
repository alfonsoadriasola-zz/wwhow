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
    if tokens then
      tokens.each{|t| t=t.split}
      self.what = tokens[0].downcase.sub('@wwhow', '') if tokens[0]
      self.where = tokens[1] if tokens[1]
      if tokens[2] then
        self.price_text = tokens[2].strip
        self.price = tokens[2].to_f
      end
      set_tags_from_what(self.what)
    end
  end

  def set_tags_from_what(whats)
    whats.downcase!
    list = whats.split(',');
    list.each do |item|
      item=item.strip;
      self.category_list.concat(item.split(' ').select{|w| w.size > 3 } )
    end
  end

  def set_tags_from_list(list)
    list[0].downcase!
    self.category_list.concat(list)
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

  def self.browse_locations
    [
            "Birmingham, Alabama",
            "Montgomery, Alabama",
            "Mobile, Alabama",
            "Huntsville, Alabama",
            "Anchorage, Alaska",
            "Phoenix, Arizona",
            "Tucson, Arizona",
            "Mesa, Arizona",
            "Glendale, Arizona",
            "Chandler, Arizona",
            "Scottsdale, Arizona",
            "Gilbert, Arizona",
            "Tempe, Arizona",
            "Peoria, Arizona",
            "Little Rock, Arkansas",
            "Los Angeles, California",
            "San Diego, California",
            "San Jose, California",
            "San Francisco, California",
            "Fresno, California",
            "Sacramento, California",
            "Long Beach, California",
            "Oakland, California",
            "Santa Ana, California",
            "Anaheim, California",
            "Bakersfield, California",
            "Riverside, California",
            "Stockton, California",
            "Chula Vista, California",
            "Irvine, California",
            "Modesto, California",
            "Fremont, California",
            "San Bernardino, California",
            "Glendale, California",
            "Huntington Beach, California",
            "Moreno Valley, California",
            "Oxnard, California",
            "Fontana, California",
            "Ontario, California",
            "Rancho Cucamonga, California",
            "Oceanside, California",
            "Santa Clarita, California",
            "Garden Grove, California",
            "Santa Rosa, California",
            "Pomona, California",
            "Corona, California",
            "Lancaster, California",
            "Salinas, California",
            "Palmdale, California",
            "Pasadena, California",
            "Hayward, California",
            "Torrance, California",
            "Escondido, California",
            "Orange, California",
            "Elk Grove, California",
            "Sunnyvale, California",
            "Fullerton, California",
            "Thousand Oaks, California",
            "El Monte, California",
            "Concord, California",
            "Visalia, California",
            "Simi Valley, California",
            "Vallejo, California",
            "Inglewood, California",
            "Roseville, California",
            "Victorville, California",
            "Santa Clara, California",
            "Costa Mesa, California",
            "Downey, California",
            "West Covina, California",
            "San Buenaventura (Ventura), California",
            "Fairfield, California",
            "Norwalk, California",
            "Burbank, California",
            "Richmond, California",
            "Daly City, California",
            "Berkeley, California",
            "Antioch, California",
            "Denver, Colorado",
            "Colorado Springs, Colorado",
            "Aurora, Colorado",
            "Lakewood, Colorado",
            "Fort Collins, Colorado",
            "Thornton, Colorado",
            "Arvada, Colorado",
            "Westminster, Colorado",
            "Pueblo, Colorado",
            "Bridgeport, Connecticut",
            "Hartford, Connecticut",
            "New Haven, Connecticut",
            "Stamford, Connecticut",
            "Waterbury, Connecticut",
            "Washington, District of Columbia",
            "Jacksonville, Florida",
            "Miami, Florida",
            "Tampa, Florida",
            "St. Petersburg, Florida",
            "Orlando, Florida",
            "Hialeah, Florida",
            "Fort Lauderdale, Florida",
            "Tallahassee, Florida",
            "Cape Coral, Florida",
            "Port St. Lucie, Florida",
            "Pembroke Pines, Florida",
            "Hollywood, Florida",
            "Coral Springs, Florida",
            "Gainesville, Florida",
            "Miami Gardens, Florida",
            "Miramar, Florida",
            "Clearwater, Florida",
            "Pompano Beach, Florida",
            "Palm Bay, Florida",
            "Atlanta, Georgia",
            "Augusta , Georgia",
            "Columbus, Georgia",
            "Savannah, Georgia",
            "Athens , Georgia",
            "Honolulu b[›], Hawaii",
            "Boise, Idaho",
            "Chicago, Illinois",
            "Aurora, Illinois",
            "Rockford, Illinois",
            "Joliet, Illinois",
            "Naperville, Illinois",
            "Springfield, Illinois",
            "Peoria, Illinois",
            "Elgin, Illinois",
            "Indianapolis , Indiana",
            "Fort Wayne, Indiana",
            "Evansville, Indiana",
            "South Bend, Indiana",
            "Des Moines, Iowa",
            "Cedar Rapids, Iowa",
            "Davenport, Iowa",
            "Wichita, Kansas",
            "Overland Park, Kansas",
            "Kansas City, Kansas",
            "Topeka, Kansas",
            "Olathe, Kansas",
            "Louisville, Kentucky",
            "Lexington, Kentucky",
            "New Orleans, Louisiana",
            "Baton Rouge, Louisiana",
            "Shreveport, Louisiana",
            "Lafayette, Louisiana",
            "Baltimore, Maryland",
            "Boston, Massachusetts",
            "Worcester, Massachusetts",
            "Springfield, Massachusetts",
            "Cambridge, Massachusetts",
            "Lowell, Massachusetts",
            "Detroit, Michigan",
            "Grand Rapids, Michigan",
            "Warren, Michigan",
            "Sterling Heights, Michigan",
            "Ann Arbor, Michigan",
            "Lansing, Michigan",
            "Flint, Michigan",
            "Minneapolis, Minnesota",
            "St. Paul, Minnesota",
            "Rochester, Minnesota",
            "Jackson, Mississippi",
            "Kansas City, Missouri",
            "St. Louis, Missouri",
            "Springfield, Missouri",
            "Independence, Missouri",
            "Columbia, Missouri",
            "Billings, Montana",
            "Omaha, Nebraska",
            "Lincoln, Nebraska",
            "Las Vegas, Nevada",
            "Henderson, Nevada",
            "North Las Vegas, Nevada",
            "Reno, Nevada",
            "Manchester, New Hampshire",
            "Newark, New Jersey",
            "Jersey City, New Jersey",
            "Paterson, New Jersey",
            "Elizabeth, New Jersey",
            "Albuquerque, New Mexico",
            "New York City, New York",
            "Buffalo, New York",
            "Rochester, New York",
            "Yonkers, New York",
            "Syracuse, New York",
            "Charlotte, North Carolina",
            "Raleigh, North Carolina",
            "Greensboro, North Carolina",
            "Durham, North Carolina",
            "Winston-Salem, North Carolina",
            "Fayetteville, North Carolina",
            "Cary, North Carolina",
            "High Point, North Carolina",
            "Wilmington, North Carolina",
            "Columbus, Ohio",
            "Cleveland, Ohio",
            "Cincinnati, Ohio",
            "Toledo, Ohio",
            "Akron, Ohio",
            "Dayton, Ohio",
            "Oklahoma City, Oklahoma",
            "Tulsa, Oklahoma",
            "Norman, Oklahoma",
            "Portland, Oregon",
            "Salem, Oregon",
            "Eugene, Oregon",
            "Gresham, Oregon",
            "Philadelphia, Pennsylvania",
            "Pittsburgh, Pennsylvania",
            "Allentown, Pennsylvania",
            "Erie, Pennsylvania",
            "Providence, Rhode Island",
            "Columbia, South Carolina",
            "Charleston, South Carolina",
            "Sioux Falls, South Dakota",
            "Memphis, Tennessee",
            "Nashville , Tennessee",
            "Knoxville, Tennessee",
            "Chattanooga, Tennessee",
            "Clarksville, Tennessee",
            "Murfreesboro, Tennessee",
            "Houston, Texas",
            "San Antonio, Texas",
            "Dallas, Texas",
            "Austin, Texas",
            "Fort Worth, Texas",
            "El Paso, Texas",
            "Arlington, Texas",
            "Corpus Christi, Texas",
            "Plano, Texas",
            "Laredo, Texas",
            "Lubbock, Texas",
            "Garland, Texas",
            "Irving, Texas",
            "Amarillo, Texas",
            "Brownsville, Texas",
            "Grand Prairie, Texas",
            "Pasadena, Texas",
            "Mesquite, Texas",
            "McAllen, Texas",
            "Carrollton, Texas",
            "Waco, Texas",
            "McKinney, Texas",
            "Denton, Texas",
            "Killeen, Texas",
            "Abilene, Texas",
            "Beaumont, Texas",
            "Midland, Texas",
            "Round Rock, Texas",
            "Lewisville, Texas",
            "Richardson, Texas",
            "Wichita Falls, Texas",
            "Salt Lake City, Utah",
            "West Valley City, Utah",
            "Provo, Utah",
            "West Jordan, Utah",
            "Virginia Beach, Virginia",
            "Norfolk, Virginia",
            "Chesapeake, Virginia",
            "Arlington , Virginia",
            "Richmond, Virginia",
            "Newport News, Virginia",
            "Hampton, Virginia",
            "Alexandria, Virginia",
            "Portsmouth, Virginia",
            "Seattle, Washington",
            "Spokane, Washington",
            "Tacoma, Washington",
            "Vancouver, Washington",
            "Bellevue, Washington",
            "Milwaukee, Wisconsin",
            "Madison, Wisconsin",
            "Green Bay, Wisconsin"
    ]
  end

end
