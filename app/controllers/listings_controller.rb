class ListingsController < ApplicationController
  geocode_ip_address
  layout "nonusers", :except => [:update_list]

  def show
    redirect_to :url=>{:action => 'index'}
  end

  # GET /listings
  def index
    if logged_in?
      redirect_to current_web_user.user
      return
    end
    safe_get_twits
    get_initial_messages
    prepare_tag_clouds
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def search
    if params[:blog_entry]
    flash[:notice] = flash[:error] = ""
    get_search_results
    prepare_tag_clouds
    render :action => 'index'
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

  def safe_get_twits
    begin
     twits = Subscription.get_twits
     Subscription.create_blog_entries(twits) if twits       
    rescue
     nil
    end

  end



end
