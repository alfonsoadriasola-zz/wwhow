class ListingsController < ApplicationController
  #geocode_ip_address
  layout "nonusers", :except => [:update_list]

  def show
    show_message
    prepare_tag_clouds
    respond_to do |format|
      format.html  {render :action => 'index'}
    end
  end


  def expand       
   @blog_entry = BlogEntry.find(params[:post_id])
   map_index = params[:map_index]
   respond_to do |format|
     format.js{
        render :partial => 'expand', :locals=>{:map_index => map_index} }
    end
  end

  def minimize_post
    @blog_entry= BlogEntry.find(params[:post_id])
    map_index = params[:map_index]
    respond_to do |format|
     format.js{
        render :partial => 'good_message_by_user', :locals=>{:map_index => map_index} }
    end
  end

  # GET /listings
  def index
    @merchants = true if params[:merchants]
    if logged_in?
      redirect_to "/who/#{current_web_user.user.name }"
      return
    end
    safe_get_tweets
    get_results_by_where_who_or_id
    prepare_tag_clouds
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def search
    @merchants = true if params[:merchants]
    if params[:blog_entry] || params[:entry_location] || params[:category_list]  || params[:author]
      flash[:notice] = flash[:error] = ""
      get_results_by_what
      prepare_tag_clouds
      if logged_in?
        @user = User.find_by_web_user_id(current_web_user.id);
        render :template =>'/users/show', :layout => 'users'
      else
        render :action => 'index'
      end

    else
      redirect_back_or_default '/'
    end


  end

  def update_list
    last_id = params[:last_id]
    @messages = BlogEntry.find :all, :conditions => "id > #{last_id||'id'}" #greather than the last one or none at all
    flash[:notice] = Time.now.strftime("updated at  %m/%d/%Y at %I:%M")
    session[:last_id]= BlogEntry.maximum("id")
  end




end
