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

  # Only search routine. All variations handled inside this app wide method.

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

    if logged_in?
      @address = current_web_user.user.address
      session[:geo_location]= BlogEntry.get_geolocation(@address)
    elsif session[:geo_location].nil?
      session[:geo_location] = BlogEntry.get_geolocation('San Francisco, CA, USA')
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
      if params[:user]
        @show_friends_only = params[:user][:show_friends_only] == "on"
      else
        @show_friends_only = current_web_user.user.show_friends_only
      end
    end

  end

  def get_search_results
    initialize_filter
    # set default map location
    if params[:default_location]!=""
      if  params[:default_location]!=session[:geo_location].full_address
        session[:geo_location]=BlogEntry.get_geolocation(params[:default_location])
      end
    end
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
      distance = @filter[:radius].to_f
      @messages = @messages.find_all{|m| m.distance_to(session[:geo_location]) <= distance}
      @messages.sort_by_distance_from(session[:geo_location])
    end

    if (logged_in? && @show_friends_only== true)
      @messages = @messages.find_all{ |m| @user.subscriptions.collect{|s|s.friend_id}.insert(0, @user.id).include?(m.user_id) }
    end

    finish_search

  end


  def get_initial_messages
    initialize_filter
    @messages = BlogEntry.find :all, :limit=>500, :order => 'created_at desc', :include =>[:user, :categories,  :ratings]
    distance = @filter[:radius].to_f

    if session[:sliders]==true
      @messages = @messages.find_all{|m| m.distance_to(session[:geo_location]) <= distance}
      @messages.sort_by_distance_from(session[:geo_location])
    end

    if (logged_in? && @show_friends_only == true )
      @messages = @messages.find_all{ |m| @user.subscriptions.collect{|s|s.friend_id}.insert(0, @user.id).include?(m.user_id) }
    end

    finish_search

  end

  protected

  def prepare_tag_clouds
    @tag_counts = BlogEntry.category_counts :limit => 50, :order => "count DESC, id DESC"
  end

  protected

  def finish_search
    @ids = @messages.collect{|m| m.id}
    if @messages.empty?
      flash[:error] = "<p> Sorry, I could not find any entries  for that </p>"
      if @filter[:sliders] == true
        flash[:error]<< "<p>(your advanced filters may be too restrictive)</p>"
      end
      if (logged_in? && @show_friends_only == true )
        flash[:error]<<"<p>( you may have to look outside of your favorite users )</p>"

      end
    end

  end

  def clear_flash
    flash[:notice] = ""
    flash[:error] = ""
  end

end