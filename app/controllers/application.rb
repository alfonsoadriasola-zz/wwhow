# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  include AuthenticatedSystem

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'fe1924bac06f3b8a2448e78b30b12a60'

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password

  def initialize_filter

    @user = current_web_user.user if logged_in?
    @filter=Hash.new
    @map_index = 0

    @filter[:category_list] = Array.new;
    @filter[:searchterms] = ""
    @filter[:rating_from] = 0
    @filter[:rating_to]=  5
    @filter[:price_from]=0
    @filter[:price_to]=500
    @filter[:radius]= 50
    @filter[:show_unmapped]=false

    # Set default location
    if params[:default_location] || params[:entry_location]
      unless @address = params[:default_location]
             @address = params[:entry_location]              
      end
    else
      if logged_in?
        @address = current_web_user.user.address
      else
        @address = User.default_location unless session[:geo_location]
      end
    end



    if @address && location = BlogEntry.get_geolocation(@address)
      session[:geo_location] = location
    end

    #set widgets
    unless params[:blog_entry].nil? then
      if params[:blog_entry][:sliders].nil? == false
        session[:sliders] =  params[:blog_entry][:sliders] == "true"
      end

      if params[:blog_entry][:map].nil? == false
        session[:map] = params[:blog_entry][:map] == "true"
      end
    else
      session[:sliders] = false
      session[:map] = false
    end

    if logged_in?
      @filter[:show_unmapped] = params[:user][:show_unmapped] == "on" if params[:user]
      @filter[:show_unmapped] = true if params[:user].nil?
    else
      @filter[:show_unmapped] = true;
    end

    if logged_in?
      if params[:user]
        @show_friends_only = params[:user][:show_friends_only] == "on"
        current_web_user.user.show_friends_only = @show_friends_only
        current_web_user.user.save(false)
      else
        @show_friends_only = current_web_user.user.show_friends_only
      end
    end
  end

  # Only search routine. All variations handled inside this app wide method.

  def get_search_results
    initialize_filter
    search_from_tag, search_from_bar, search_by_author, search_by_location= false
    cond = String.new
    search_by_location = (params[:entry_location] ||  params[:default_location]) && (params[:blog_entry].nil?)
    search_by_author = (params[:blog_entry] && params[:blog_entry][:author_id] != "")
    search_by_author_url = (params[:author] && params[:blog_entry].nil?)
    default_logged_in_search = search_by_author_url && ( logged_in? && current_web_user.login == params[:author] )
    search_from_tag = params[:category_list] ||  ( params[:blog_entry] && params[:blog_entry][:category_list] && params[:blog_entry][:category_list] != "" )
    search_from_bar =  params[:blog_entry] && !search_from_tag
    use_sliders = session[:sliders]

    if (!search_by_author && !search_by_author_url && !search_by_location )

      #did one click a tag?
      if params[:category_list] || ( params[:blog_entry][:category_list] && params[:blog_entry][:category_list] != "" )
        @filter[:category_list] = params[:blog_entry][:category_list] if params[:blog_entry]
        @filter[:category_list] = params[:category_list] if params[:category_list]
      else
        #prepare search input, look at things tagged with search terms as well     
        @filter[:category_list] =  params[:blog_entry][:search].split(',')
        @filter[:category_list].each{|item| item = item.strip} if @filter[:category_list].size  > 1
        @filter[:searchterms] = params[:blog_entry][:search].strip unless params[:blog_entry][:search].nil?
      end

      #prepare filters for sliders
      if use_sliders
        @filter[:price_from]=params[:blog_entry][:price_from] unless params[:blog_entry][:price_from].nil?
        @filter[:price_to]=params[:blog_entry][:price_to] unless params[:blog_entry][:price_to].nil?

        @filter[:rating_from] = params[:blog_entry][:search_rating_from] unless params[:blog_entry][:search_rating_from].nil?
        @filter[:rating_to]= params[:blog_entry][:search_rating_to] unless params[:blog_entry][:search_rating_to].nil?

        @filter[:radius] = params[:blog_entry][:radius] unless params[:blog_entry][:radius].nil?
      end

      #the second one is for tagged by searching
      @messages, @messages2 = Array.new
      if search_from_bar
        cond = "1=1 "
      elsif search_from_tag
        cond = "1=0 "
      end

      #conditions for distance
      cond = cond + "AND (" + BlogEntry.distance_sql(session[:geo_location], :miles, :sphere) << "<= #{@filter[:radius]}"
      cond = cond + " OR blog_entries.lat is null " if @filter[:show_unmapped]
      cond = cond + ")"

      #conditions for searching at
      cond = cond + %Q{ AND lower(what) LIKE '%#{@filter[:searchterms].downcase.gsub(/[.,']/, '')}%' }
      @messages = BlogEntry.find :all, :conditions => cond, :order => 'blog_entries.created_at desc', :limit => 200, :include =>[:user, :categories, :ratings]

      # but you also need to check tags because not only is the what a good candidate, the tags are there for search too
      @filter[:category_list] = params[:category_list] if params[:category_list]
      @messages2 = BlogEntry.find_tagged_with @filter[:category_list], {:on=> :categories, :order => 'blog_entries.created_at desc', :limit => 200, :include =>[:user, :ratings] }
      @messages2 = @messages2.find_all{|m| m.distance_to(session[:geo_location]) <= @filter[:radius].to_f || ( @filter[:show_unmapped] && m.lat.nil?)}
      @filter[:searchterms]  = @filter[:category_list]
      @messages.concat(@messages2) if @messages2

      @messages = @messages.uniq
      #search by author (only possible through tag)
    elsif search_by_author  || search_by_author_url  && !default_logged_in_search      
      if params[:blog_entry].nil? && params[:author]
        params[:blog_entry]=Hash.new
        if author=  User.find_by_name(params[:author])
          params[:blog_entry][:author_id] = author.id 
        end
      end

      @messages =BlogEntry.find :all, :conditions => {:user_id => params[:blog_entry][:author_id]}, :order => 'blog_entries.created_at desc', :include =>[:user, :ratings], :limit => 500
    elsif search_by_location || default_logged_in_search
      get_initial_messages
    else
      #fallback
      get_initial_messages
    end

    if session[:sliders]==true
      @messages = @messages.find_all{|m| m.rating >=@filter[:rating_from].to_f && m.rating <= @filter[:rating_to].to_f }
      @messages = @messages.find_all{|m| m.price >= @filter[:price_from].to_f && m.price <= @filter[:price_to].to_f }
    end


    finish_search

  end


  def get_initial_messages
    initialize_filter
    cond=BlogEntry.distance_sql(session[:geo_location], :miles, :sphere) << "<= #{@filter[:radius]}"
    cond = cond + " OR blog_entries.lat is null " if @filter[:show_unmapped]
    @messages = BlogEntry.find :all,
            :conditions => cond,
            :limit=>100,
            :order => 'blog_entries.created_at desc', :include =>[:user, :categories,  :ratings]
    finish_search
  end

  protected

  def prepare_tag_clouds
    @tag_counts = BlogEntry.category_counts :limit => 50, :order => "count DESC, id DESC"
    @active_users = User.find_active
  end

  protected

  def finish_search
    if (logged_in? && @show_friends_only == true)
      @messages = @messages.find_all{ |m| @user.subscriptions.collect{|s|s.friend_id}.insert(0, @user.id).include?(m.user_id) }
    end
    @messages.compact

    @messages =  @messages.sort_by{|m| m.created_at}.reverse!
    @location = "#{session[:geo_location].lat},#{session[:geo_location].lng}" if session[:geo_location]&&session[:geo_location].lat
    @mapmessages = @messages.reject{|m| m.lat.nil?}
    @mapmessages = @mapmessages[0..98] if @mapmessages.size > 98
    if @messages.empty?
      flash[:error] = "Sorry, please try again, couldn&rsquo;t find a match for that near your location <br/> "
      if session[:sliders]==true
        flash[:error]<< "<em>(your advanced filters may be too restrictive)</em><br/>"
      end
      if (logged_in? && @show_friends_only == true )
        flash[:error]<<"<em>( you may have to look outside of your favorite users )</em><br/>"
      end
      if (logged_in? && @filter[:show_unmapped]==false)
        flash[:error]<<"<em>( you are only seeing mapped posts)</em><br/>"
      end
      flash[:error]<<"<p/>"
    end

  end

  def clear_flash
    flash[:notice] = ""
    flash[:error] = ""
  end

  def update_current_user_ranking
    if logged_in?
      current_web_user.user.rated = User.rate(current_web_user.user);
      current_web_user.user.ranked = User.rank(current_web_user.user.rated);
      current_web_user.user.save(false)
    end
  end

  def update_active_user_ranking
    users = BlogEntry.find(:all, :select => 'DISTINCT user_id as id', :conditions =>['created_at > ?', Time.now - 60*60*24*180], :limit => 500)
    users.each{|ur| u= User.find(ur.id); u.rated = User.rate(u); u.ranked = User.rank(u.rated); u.save(false);}
  end


  def safe_get_tweets
    begin
      tweets = Subscription.get_tweets
      Subscription.create_blog_entries(tweets) if tweets
    rescue
      nil
    end

  end

end