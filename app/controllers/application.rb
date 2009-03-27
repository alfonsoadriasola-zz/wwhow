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



  #prepare filter, session

  def initialize_filter

    @user = current_web_user.user if logged_in?
    @filter=Hash.new
    @ids = Array.new

    @filter[:category_list] = Array.new;
    @filter[:searchterms] = ""
    @filter[:rating_from] = 0
    @filter[:rating_to]=  5
    @filter[:price_from]=0
    @filter[:price_to]=500
    @filter[:radius]= 50
    @filter[:show_unmapped]=false


    # Set default location
    if logged_in?
      if params[:default_location].nil? && current_web_user.user.address == ""
        @address = 'San Francisco, CA, USA'
      elsif !params[:default_location].nil? && params[:default_location] != current_web_user.user.address
        @address = params[:default_location]
      elsif session[:geo_location].nil?
        @address = current_web_user.user.address
      else
        @address = current_web_user.user.address
      end
    else
      if  params[:default_location] && params[:default_location] != ""
        @address = params[:default_location]
      elsif session[:geo_location].nil?
        @address = 'San Francisco, CA, USA'
      else
        @address = session[:geo_location]
      end
    end

    session[:debug] = session[:geo_location].nil?

    if session[:geo_location].nil?
      session[:geo_location] = BlogEntry.get_geolocation(@address)
    else
      unless session[:geo_location] == @address
        session[:geo_location] = BlogEntry.get_geolocation(@address)
      end
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

    search_from_tag, search_from_bar, search_by_author = false
    cond = String.new
    search_by_author = params[:blog_entry][:author_id] != ""
    search_from_bar = params[:blog_entry][:search] != ""
    use_sliders = session[:sliders]
    if !search_by_author

      #did one click a tag?
      if params[:blog_entry][:category_list] != ""
        @filter[:category_list] = params[:blog_entry][:category_list]
        search_from_tag = true;
      else
        #prepare search input, look at things tagged with search terms as well
        search_from_bar = true;
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
        cond = " 1=1 "
      end

      if search_from_tag
        cond = "1=0 "
      end
      cond = cond + %Q{ AND lower(what) LIKE '#{@filter[:searchterms].downcase.gsub(/[.,']/, '')}%' }
      @messages = BlogEntry.find :all, :conditions => cond, :order => 'created_at desc', :include =>[:user, :categories, :ratings]

      # but you also need to check tags because not only is the what a good candidate, the tags are there for search too
      if !@filter[:category_list].nil?
        @messages2 = BlogEntry.find_tagged_with @filter[:category_list], {:on=> :categories, :order => 'blog_entries.created_at desc', :include =>[:user, :ratings] }
        @filter[:searchterms]  = @filter[:category_list]
        @messages.concat(@messages2) if @messages2
      end
      @messages = @messages.uniq
      #search by author (only possible through tag)
    elsif params[:blog_entry] && params[:blog_entry][:author_id]!= ""
      @messages =BlogEntry.find :all, :conditions => {:user_id => params[:blog_entry][:author_id]}, :order => 'blog_entries.created_at desc', :include =>[:user, :ratings], :limit => 100

    else
      #fallback
      get_initial_messages
    end

    if session[:sliders]==true
      @messages = @messages.find_all{|m| m.rating >=@filter[:rating_from].to_f && m.rating <= @filter[:rating_to].to_f }
      @messages = @messages.find_all{|m| m.price >= @filter[:price_from].to_f && m.price <= @filter[:price_to].to_f }
    end

    distance = @filter[:radius].to_f
    @messages = @messages.find_all{|m| m.distance_to(session[:geo_location]) <= distance || ( @filter[:show_unmapped] && m.lat.nil?)}
    @messages.sort_by_distance_from(session[:geo_location])

    if (logged_in? && @show_friends_only== true)
      @messages = @messages.find_all{ |m| @user.subscriptions.collect{|s|s.friend_id}.insert(0, @user.id).include?(m.user_id) }
    end

    finish_search

  end


  def get_initial_messages
    initialize_filter
    @messages = BlogEntry.find :all, :limit=>500, :order => 'created_at desc', :include =>[:user, :categories,  :ratings]
    distance = @filter[:radius].to_f


    @messages = @messages.find_all{|m| m.distance_to(session[:geo_location]) <= distance || ( @filter[:show_unmapped] && m.lat.nil?)}
    @messages.sort_by_distance_from(session[:geo_location])

    if (logged_in? && @show_friends_only == true )
      @messages = @messages.find_all{ |m| @user.subscriptions.collect{|s|s.friend_id}.insert(0, @user.id).include?(m.user_id) }
    end

    finish_search

  end

  protected

  def prepare_tag_clouds
    @tag_counts = BlogEntry.category_counts :limit => 50, :order => "count DESC, id DESC"
    @active_users = User.find_active
  end

  protected

  def finish_search
    @ids = @messages.collect{|m| m.id }
    if @messages.empty?
      flash[:error] = "Sorry, try again. Couldn&rsquo;t find a match for that <br/>"
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
    users.each{|ur| u= User.find(ur.id); u.rated = User.rate(u); u.ranked = User.rank(u.rated); u.save;}
  end


  def safe_get_twits
    begin
      twits = Subscription.get_twits
      Subscription.create_blog_entries(twits) if twits
    rescue
      nil
    end

  end

end