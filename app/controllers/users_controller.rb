class UsersController < ApplicationController
  # GET /users
  # GET /users.xml

  layout 'users', :except => [:destroy_blog_entry, :update_blog_entry, :edit_blog_entry]

  before_filter :login_required

  def index
    @user = User.find_by_web_user_id(current_web_user)
    if current_web_user.is_admin?
      @users = User.find(:all) 
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @users }
      end
    else
      redirect_to  @user
    end
  end

  # GET /users/1
  # GET /users/1.xml

  def show
    if params[:id].to_i > 0
      @user = User.find(params[:id])
    else
      @user = User.find_by_name(params[:id])
    end

    get_results_by_where_who_or_id
    safe_get_tweets
    prepare_tag_clouds
    respond_to do |format|
      if @user
        format.html {render :action => 'show'}
      else
        format.html {redirect_to :controller => 'listings', :action => 'index' }
      end
    end
  end

  # GET /users/new
  # GET /users/new.xml

  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit

  def edit
    @user = User.find_by_id(params[:id])
  end

  # POST /users
  # POST /users.xml

  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save

        @user.subscriptions.create(:friend_id => @user.id);
        @master = User.find_by_name "cheapcheap"
        @master.subscriptions.create(:friend_id => @user.id);

        flash[:notice] = 'User was successfully created.'

        format.html { redirect_to(@user) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml

  def update
    @user = User.find(params[:id])
    success = @user.update_attributes(params[:user])
    success = success && @user.web_user.update_attributes(params[:web_user]) unless params[:web_user][:password].blank?

    respond_to do |format|
      if success
        flash[:notice] = 'Thanks for keeping your profile up to date.'
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        flash[:errors] = @user.errors.concat(@user.web_user.errors)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end

  end

  # DELETE /users/1
  # DELETE /users/1.xml

  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

  def new_msg
    @user = User.find(params[:user][:id])
    whats =  params[:blog_entry][:what].strip
    wheres = params[:blog_entry][:where].strip
    price = params[:blog_entry][:price]
    categories = params[:category_list]

    @msg = @user.blog_entries.new(
            :what => whats.downcase,
            :where => wheres,
            :price => price.to_f,
            :price_text => price  )

    @msg.set_tags_from_what(whats) unless @msg.set_tags_from_list(categories)

    @msg.geocode_where
    respond_to do |format|
      if @msg.save
        update_current_user_ranking
        format.html { redirect_to "/who/#{@user.name}/"}
        format.xml  { render :xml => @msg, :status => :created, :location => @user }
      else
        flash[:error] = @msg.errors.full_messages.collect{|m| "<li>#{m}</li>"}
        flash[:error] = "<ul>#{flash[:error]}</ul>"
        format.html { redirect_to "/who/#{@user.name}/"}
        format.xml  { render :xml => @msg.errors, :status => :unprocessable_entity }
      end
    end
  end

  def search 
    get_results_by_what
    prepare_tag_clouds
    render :action => 'show', :user_id => User.find_by_web_user_id(current_web_user.id)
  end

  def destroy_blog_entry
    return unless logged_in?
    @current_user = current_web_user
    be = BlogEntry.find params[:blog_entry_id].to_i
    @user = @current_user.user
    be.category_list = ""
    be.destroy;
    update_current_user_ranking
    render :update do |page|
      page.remove("tr#{be.id}")
      page.visual_effect :highlight, "messageList"
    end

  end

  def edit_blog_entry
    return unless logged_in?
    @user = current_web_user.user
    @blog_entry= BlogEntry.find(params[:blog_entry_id])
    @map_index = params[:map_index]

    respond_to do |format|
      format.js{
        render :partial => 'edit_blog_entry'}
    end

  end

  
  def update_blog_entry
    @user = current_web_user.user
    @blog_entry= BlogEntry.find(params[:blog_entry_edit][:id])
    @map_index = params[:blog_entry_edit][:map_index].to_i-1

    @blog_entry.what = params[:blog_entry_edit][:what] unless params[:blog_entry_edit][:what].nil?
    @blog_entry.where = params[:blog_entry_edit][:where] unless params[:blog_entry_edit][:where].nil?
    @blog_entry.category_list = params[:blog_entry_edit][:category_list] unless params[:blog_entry_edit][:category_list].nil?
    @blog_entry.category_list = params[:master_category_list] unless  params[:master_category_list].nil?

    price = params[:blog_entry_edit][:price]
    @blog_entry.price = price.to_f
    @blog_entry.price_text = price

    if @blog_entry.save
      @blog_entry.geocode_where
      @mapmessages=[@blog_entry] if @blog_entry.lat
      @blog_entry.save(false)
      update_current_user_ranking
      respond_to do |format|
        format.js
        format.html {redirect_to "/who/#{@user.name}/"}
      end
    else
      flash[:error] = @blog_entry.errors.full_messages.collect{|m| "<li>#{m}</li>"}
      flash[:error] = "<ul>#{flash[:error]}</ul>"
      respond_to do |format|
        format.js   {render :action => 'edit_blog_entry'}
        format.html { redirect_to "/who/#{@user.name}/"}
      end
    end
  end

  def cancel_update_blog_entry
    @user = current_web_user.user
    @blog_entry= BlogEntry.find(params[:blog_entry_id])
    @map_index = params[:map_index].to_i-1
    respond_to do |format|
      format.js
      format.html {redirect_to "/who/#{@user.name}/"}
    end
  end

  def manage_favorites
    @user = User.find(params[:id])
    @ids = @user.subscriptions.find(:all, :conditions=>(:approved != false)).collect{|s| s.friend_id}
    @users = User.find @ids
    respond_to do |format|
      format.html { render :action => 'index'}
    end

  end

  def remove_user_from_favorites
    @user = current_web_user.user
    @friend = User.find(params[:friend_id]);
    respond_to do |format|
      if @user.subscriptions.find_by_friend_id(@friend.id).destroy
        flash[:notice] = "  #{@friend.name} .. no longer special"
        format.html {redirect_to(@user) }
        format.js
      else
        flash[:error] = flash[:notice] = "Couldn't remove him. something went wrong"
        format.html { render :action => "manage_favorites" }
        format.js
      end
    end
  end

  def add_user_to_favorites
    @user = current_web_user.user
    @friend = User.find(params[:friend_id]);
    respond_to do |format|
      if @user.subscriptions.create(:friend_id => @friend.id)
        flash[:notice] = "  #{@friend.name} is now a favorite!"
        format.html {redirect_to(@user) }
        format.js
      else
        format.html { render :action => "show" }
        format.js
      end
    end
  end

  # Blok user is not filterable on prefs, have to remove from blocked user list

  def block_user
    @user = current_web_user.user
    @foe = User.find(params[:foe_id]);
    respond_to do |format|
      if @user.subscriptions.create(:friend_id => @foe.id, :approved => false)
        flash[:notice] = "  #{@friend.name} will trouble you no longer!"
        format.html {redirect_to(@user) }
        format.js
      else
        format.html { render :action => "show" }
        format.js
      end
    end
  end

  def close_account


  end

end
