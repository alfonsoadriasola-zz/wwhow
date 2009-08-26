require 'yaml'
class PriceSpider < Subscription

  def self.config
    config=YAML::load(File.open("#{RAILS_ROOT}/config/pricespider.yml"))
  end

  def self.get_products_by_category(category)
    products = []
    response  = Net::HTTP.get URI.parse("http://mobi.pricespider.com/Service.svc/GetLocalDeals?countryTypeId=1&categoryId=#{category[:category_id]}")
    products << ActiveSupport::JSON.decode(response).flatten
  end


  def self.get_all_products_list
    products = []
    get_categories.each do |category|
      products<< get_products_by_category(category).flatten
    end
    products.flatten
  end

#  GetProductSummary
#          Example URL: http://mobi.pricespider.com/Service.svc/GetProductSummary?uid=a37267d473ab43d5a9037b9a840fa97c&productId=1297114
#          Returns details about a given product
#
  def self.get_product_summary (product)
    response = Net::HTTP.get URI.parse("http://mobi.pricespider.com/Service.svc/GetProductSummary?uid=#{ENV['PRICE_SPIDER_API_KEY']}&productId=#{product['ProductId']}")
    ActiveSupport::JSON.decode(response)
  end

#GetLocalSellerData
#-          Example URL: http://mobi.pricespider.com/Service.svc/GetLocalSellerData?uid=a37267d473ab43d5a9037b9a840fa97c&productId=1297114&geoLocation=37.8118,-122.2553
#-          Returns all local sellers offering a given product. Seller records include records of up to 5 of the closest location local stores near the passed geoLocation coordinates.
  def self.get_local_sellers(product, location)
    url = "http://mobi.pricespider.com/Service.svc/GetLocalSellerData?uid=#{ENV['PRICE_SPIDER_API_KEY']}&productId=#{product['ProductId']}&geoLocation=#{location.lat},#{location.lng}"
    response = Net::HTTP.get URI.parse(url)
    result = ActiveSupport::JSON.decode(response)
  end


#GetProductHistoryData
#
#-          Example URL: http://mobi.pricespider.com/Service.svc/GetProductHistoryData?productId=1297114&lookbackDays=90&aggregateByHour=false
#
#-          Returns the median and lowest prices recorded for the specified number of lookback Days from today
#
  def self.get_product_history(product)
    url = "http://mobi.pricespider.com/Service.svc/GetProductHistoryData?productId=#{product['ProductId']}&lookbackDays=30&aggregateByHour=false"

    response = Net::HTTP.get URI.parse(url)
    result = ActiveSupport::JSON.decode(response)

  end

#
#GetProductSellerHistoryData
#
#-          Example URL: http://mobi.pricespider.com/Service.svc/GetProductSellerHistoryData?productId=1297479&sellerId=194&lookbackDays=90&aggregateByHour=false

  def self.get_product_seller_history_data(product, seller)
    url = "http://mobi.pricespider.com/Service.svc/GetProductSellerHistoryData?productId=#{product[:product_id]}&sellerId=#{seller[:id]}&lookbackDays=90&aggregateByHour=false"
    response = Net::HTTP.get URI.parse(url)
    result = ActiveSupport::JSON.decode(response)
  end

  def self.get_categories
    [{:category_id => "100162", :description => "Desktops & Workstations", :category => "Toys"},
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

  end

  def self.create_post_by_product_seller(product, seller)

    username, sellername, address1, city, zip, where, what=''
    local_store = {}
    category_list = []

    username = 'pricespider'
    begin

      local_store = seller['LocalStores'][0]
      sellername = seller['SellerName']
      address1 = local_store['StoreAddress1']
      city = local_store['City']
      zip = local_store['Zip']

      where = sellername<<'@'<<address1<<', '<<city<<', '<< zip
      what  = product['Title']
      lat = local_store['Latitude']
      lng = local_store['Longitude']

      category_list << 'Electronics'
      category_list << product['CategoryName']
      price = seller['Price']

      user= User.find_or_create_by_name(username)
      user.save(false)
      be = BlogEntry.create(:what => what, :where => where, :price => price, :lat => lat, :lng => lng, :user_id => user.id, :price_text => price )
      be.category_list = category_list.join(",")
      be.save
    rescue   SyntaxError, NameError => error
      y error, sellername, address1, city, zip, where, what, local_store, be
    end

  end

  def self.seed_location(location, limit)
    productids = PriceSpider.get_all_products_list
    selection = []
    newposts = tries = 0
    while (newposts < limit && tries < 3)  do
      dice_toss =  rand(productids.size-limit)
      selection = productids[dice_toss..dice_toss+limit] if limit> 0
      selection.each do |p|
        product = {'ProductId' => p}
        product = PriceSpider.get_product_summary(product)['Product']
        seller = PriceSpider.get_local_sellers(product, location);
        seller = seller[0] if seller
        lowest_price = PriceSpider.get_product_history(product)['LowestPrices'].uniq[0]
        if product && seller && lowest_price >= seller['Price'] && seller['Price'] != 0
          PriceSpider.create_post_by_product_seller(product, seller)
          newposts += 1
        end
        productids = productids - selection
      end
      tries +=1
    end
    newposts
  end

  def self.seed_big_cities
    big_cities= config['big_cities'].split(",: ")
    big_cities.each do |city|
      puts city
      puts PriceSpider.seed_location(User.geocode(city), 7).size
    end
  end

  def self.seed_more_locations
    cities=config['wwhow_locations'].split(",;")
    cities.each do |city|
      puts city
      puts PriceSpider.seed_location(User.geocode(city), 7).size
    end
  end
end

