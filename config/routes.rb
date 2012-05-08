Theswopspace::Application.routes.draw do
  get "swop/start"
  get "iotm/list"
  get "iotm/previous"
  get "welcome/index"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action
  
  #access mappings
  match 'access/authenticate' => 'access#authenticate', :via => :post
  match 'access/logout' => 'access#logout'
  match 'access/forgot' => 'access#forgot'
  match 'access/resetpassword' => 'access#resetpassword', :via => :post
  match 'access/register' => 'access#register'
  match 'access/doregister' => 'access#doregister'
  match 'access/verify' => 'access#verify', :via => :get
  
  #user profile mappings
  match 'user/profile' => 'user#profile', :via => :get
  match 'user/saveprofile' => 'user#saveprofile', :via => :post
  match 'user/profile/manage' => 'user#editprofile', :via => :get
  match 'user/viewprofile/:id' => 'user#viewprofile', :via => :get
  match 'users/list' => 'user#userlist', :via => :get
  
  #image controller mappings
  match 'image/avatar/:id' => 'image#get_avatar', :via => :get
  match 'image/get/:id' => "image#get_image", :via => :get
  
  #item mappings
  match 'user/inventory/manage' => 'item#manage', :via => :get
  match 'user/inventory/new' => 'item#new'
  match 'item/create' => 'item#create', :via => :post
  match 'item/edit/:id' => 'item#edititem', :via => :get
  match 'item/edit' => 'item#edit', :via => :post
  match 'items/browse' => 'item#browse'
  match 'items/details/:id' => 'item#details'
  match 'items/rate' => 'item#rate', :via => :post
  match 'items/images/:id' => 'item#imagesforitem', :via => :get
  match 'items/nominate' => 'item#nominate', :via => :post
  
  #item of the month mappings
  match 'iotm/list' => 'iotm#list', :via => :get
  match 'iotm/vote' => 'iotm#vote', :via => :post
  
  #swop section mappings
  match 'items/swop/:id' => 'swop#start'
  match 'swop/suggest' =>  'swop#suggest'
  match 'swop/index' => 'swop#index'
  match 'swops/pending' => 'swop#pending'
  match 'swop/view/:id' => 'swop#details'
  match 'swop/update/' => 'swop#update', :via => :post

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'
  root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
