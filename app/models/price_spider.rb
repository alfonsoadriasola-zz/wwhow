class PriceSpider < Subscription

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
  def get_product_history(product)
    url = "http://mobi.pricespider.com/Service.svc/GetProductHistoryData?productId=#{product[:product_id]}&lookbackDays=30&aggregateByHour=false"

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

    username = 'pricespider'
    begin

      if local_store = seller[0]['LocalStores'][0] && product['Title'] && product['CategoryName']
        where = %Q{#{seller[0]['SellerName']}@#{local_store['StoreAddress1']} #{','+ local_store['City'] if local_store['City']}, #{local_store['Zip']}}
        what  = product['Title']
        lat = local_store['Latitude']
        lng = local_store['Longitude']
        category_list  = []
        category_list << 'Electronics'
        category_list << product['CategoryName']
        price = seller[0]['Price']

        if user= User.find_or_create_by_name(username)
          user.save(false)
          be = BlogEntry.create(:what => what, :where => where, :price => price, :lat => lat, :lng => lng, :user_id => user.id, :price_text => price )
          be.category_list = category_list.join(",")
          be.save(false)
        end
      end
    rescue   SyntaxError, NameError => error
      y error
      y seller
      y product
    end

  end

  def self.seed_location(location, limit)

    productids = PriceSpider.get_all_products_list
    dice_toss =  rand(productids.size)
    productids = productids[dice_toss..dice_toss+limit] if limit> 0
    productids.each do |p|
      product = PriceSpider.get_product_summary({'ProductId' => p})['Product']
      seller = PriceSpider.get_local_sellers(product, location);
      PriceSpider.create_post_by_product_seller(product, seller) if product && seller
    end



  end

  def self.seed_big_cities

    ["New York,New York",
     "Los Angeles,California",
     "Chicago,Illinois",
     "Houston,Texas",
     "Phoenix,Arizona",
     "Philadelphia,Pennsylvania",
     "San Antonio,Texas",
     "Dallas,Texas",
     "San Diego,California",
     "San Jose,California",
     "Detroit,Michigan",
     "San Francisco,California",
     "Jacksonville,Florida",
     "Indianapolis,Indiana",
     "Austin,Texas",
     "Columbus,Ohio",
     "Fort Worth,Texas",
     "Charlotte,North Carolina",
     "Memphis,Tennessee",
     "Baltimore,Maryland",
     "El Paso,Texas",
     "Boston,Massachusetts",
     "Milwaukee,Wisconsin",
     "Denver,Colorado",
     "Seattle,Washington",
     "Nashville,Tennessee",
     "Washington,District of Columbia",
     "Las Vegas,Nevada",
     "Portland,Oregon",
     "Louisville,Kentucky",
     "Oklahoma City,Oklahoma",
     "Tucson,Arizona",
     "Atlanta,Georgia"].each do |city|
      puts city
      puts PriceSpider.seed_location(User.geocode(city), 8).size


    end


  end

end

