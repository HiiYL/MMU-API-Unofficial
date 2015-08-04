Rails.application.routes.draw do
  get 'update_bulletin' => 'api#update_bulletin'
  post 'login_mmls' => 'api#login_mmls'
  post 'login_camsys' => 'api#login_camsys'
  post 'login_camsys_v2' => 'api#login_camsys_v2'

  post 'simple_timetable_api' => 'api#simple_timetable'
  get 'mmls_api' => 'api#mmls'
  post 'mmls_api' => 'api#mmls', :defaults => { :format => 'json' }
  get 'bulletin_api' => 'api#bulletin_api'
  get 'bulletin' => 'api#bulletin'
  post 'attendance_api' => 'api#attendance'
  get 'test' => 'api#test'

  post 'login_mmls_fast' => "api#login_mmls_fast"
  # get 'timetable_api' => 'api#timetable'
  post 'timetable_api' => 'api#timetable'

  post 'refresh_subject' => 'api#mmls_refresh_subject'

  post 'refresh_token' => 'api#refresh_token'

  post 'refresh' => 'api#refresh'

  root 'static_pages#home'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
