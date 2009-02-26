ActionController::Routing::Routes.draw do |map|


  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'web_users', :action => 'create'
  map.signup '/signup', :controller => 'web_users', :action => 'new'
  map.activate '/activate/:activation_code', :controller => 'web_users', :action => 'activate', :activation_code => nil  
  map.forgot_password '/forgot_password', :controller => 'web_users', :action => 'forgot_password'
  map.after_forgot_password '/after_forgot_password', :controller => 'web_users', :action => 'after_forgot_password'
  map.reset_password '/reset_password/:code', :controller => 'web_users', :action => 'reset_password'
  map.about '/about', :controller => 'common', :action => 'about'
  map.help  '/help' , :controller => 'common', :action => 'help'
  map.tos   '/tos', :controller =>  'common', :action => 'tos'
  map.privacy '/privacy', :controller => 'common', :action => 'privacy'

  
  map.resources :web_users
  map.resource :session
  map.resources :users

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  map.connect ':name', :controller => 'users', :action => 'find_by_name'

  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "listings"



  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

end
