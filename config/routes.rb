require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  scope "(:locale)", locale: /vi|en/ do
    delete "/logout", to: "sessions#destroy"
    root "static_pages#index"
    get "static_pages/index"
    get "ajax_products", to: "static_pages#load_products"
    get "/cart", to: "carts#index", as: "cart_index"
    devise_for :users
    as :user do
      get "login" => "devise/sessions#new"
      post "login" => "devise/sessions#create"
      delete "signout" => "devise/sessions#destroy"
      get "signup" => "devise/registrations#new"
    end
    resources :users, only: %i(new create show)
    resources :products do
      collection do
        get :search
        get :filter_by_category
      end
    end
    resources :carts, only: %i(index create update destroy) do
      patch :update_selection, on: :member
    end
    resources :addresses, only: %i(new create)
    get "orders/order_info"
    post "orders", to: "orders#create"
    resources :orders, only: %i(show index) do
      member do
        patch :update_status
      end
      resources :feedbacks, only: %i(create update)
    end
    namespace :admin do
      resources :orders, only: %i(index show) do
        member do
          patch :update_status
        end
        collection do
          put :batch_update
        end
      end
      resources :products, only: %i(index new create edit update show destroy)
      resources :users, only: %i(index)
      resources :statistics, only: %i(index)
    end
    namespace :api do
      namespace :v1 do
        namespace :admin do
          resources :products, only: %i(index new create edit update destroy)
        end
      end
    end
  end
end
