# == Route Map
#
#               Prefix Verb   URI Pattern                    Controller#Action
#          rails_admin        /admin                         RailsAdmin::Engine
#     new_user_session GET    /users/sign_in(.:format)       devise/sessions#new
#         user_session POST   /users/sign_in(.:format)       devise/sessions#create
# destroy_user_session DELETE /users/sign_out(.:format)      devise/sessions#destroy
#        user_password POST   /users/password(.:format)      devise/passwords#create
#    new_user_password GET    /users/password/new(.:format)  devise/passwords#new
#   edit_user_password GET    /users/password/edit(.:format) devise/passwords#edit
#                      PATCH  /users/password(.:format)      devise/passwords#update
#                      PUT    /users/password(.:format)      devise/passwords#update
#                 root GET    /                              home#index
# 
# Routes for RailsAdmin::Engine:
#   dashboard GET         /                                      rails_admin/main#dashboard
#       index GET|POST    /:model_name(.:format)                 rails_admin/main#index
#         new GET|POST    /:model_name/new(.:format)             rails_admin/main#new
#      export GET|POST    /:model_name/export(.:format)          rails_admin/main#export
# bulk_delete POST|DELETE /:model_name/bulk_delete(.:format)     rails_admin/main#bulk_delete
#    nestable GET|POST    /:model_name/nestable(.:format)        rails_admin/main#nestable
# bulk_action POST        /:model_name/bulk_action(.:format)     rails_admin/main#bulk_action
#        show GET         /:model_name/:id(.:format)             rails_admin/main#show
#        edit GET|PUT     /:model_name/:id/edit(.:format)        rails_admin/main#edit
#      delete GET|DELETE  /:model_name/:id/delete(.:format)      rails_admin/main#delete
# show_in_app GET         /:model_name/:id/show_in_app(.:format) rails_admin/main#show_in_app
require 'sidekiq/web'
Rails.application.routes.draw do
  if Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      expected_user = ENV['SIDEKIQ_WEB_USERNAME'].to_s
      expected_pass = ENV['SIDEKIQ_WEB_PASSWORD'].to_s
      next false if expected_user.empty? || expected_pass.empty?

      ActiveSupport::SecurityUtils.secure_compare(username, expected_user) &
        ActiveSupport::SecurityUtils.secure_compare(password, expected_pass)
    end
  end
  mount Sidekiq::Web => '/sidekiq'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  devise_for :users, controllers: { registrations: 'users/registrations' }

  # 未登录访客落到公开落地页；已登录用户直达仪表盘——`authenticated` 块必须
  # 排在 `root 'landing#show'` 之前，Rails 路由按声明顺序先匹配先赢（P5 Task 10）。
  authenticated :user do
    root 'home#index', as: :authenticated_root
  end
  root 'landing#show'

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
  resources :products do
    member do
      get :show_version
      get :upload_file
      patch :do_upload_file
      get :edit_file
      patch :update_file
      get :apply
      patch :do_apply
    end
    collection do
      post :do_develop_audit
      post :do_flow_audit
      post :do_active_audit
      post :do_failed_audit
      get :import
      post :do_import
    end
  end

  resources :instances do
    member do
      get :show_version
      get :upload_file
      patch :do_upload_file
      get :edit_file
      patch :update_file
      get :apply
      patch :do_apply
    end
    collection do
      post :do_develop_audit
      post :do_flow_audit
      post :do_active_audit
      post :do_failed_audit
      get :import
      post :do_import
    end
  end

  resources :audits do
    collection do
      get :products
      get :instances
      get :technologies
    end
  end
  resources :technologies do
    member do
      get :show_version
      get :upload_file
      patch :do_upload_file
      get :edit_file
      patch :update_file
      get :apply
      patch :do_apply
    end
    collection do
      post :do_develop_audit
      post :do_flow_audit
      post :do_active_audit
      post :do_failed_audit
    end
  end
  resources :notices do
    collection do
      get :receives
      get :sends
    end
    member do
      get :show_notice
      get :reply
      patch :do_reply
      patch :read
    end
  end
  resources :home, only: [:index] do
    collection do
      get :cytoscape
      get :files_search
    end
  end

  resources :matters do
    member do
      get :upload_file
      patch :do_upload_file
      get :notices
      patch :send_notice
      patch :countersign
      patch :agree
    end
  end
end
