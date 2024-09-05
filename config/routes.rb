Rails.application.routes.draw do
  scope "(:locale)", locale: /vi|en/ do
    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"
    root "static_pages#index"
    get "static_pages/index"
    get "ajax_products", to: "static_pages#load_products"
    get "/cart", to: "carts#index", as: "cart_index"
    get "/signup", to: "users#new"
    post "/signup", to: "users#create"
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
      end
      resources :products, only: %i(index new create edit update show destroy)
      resources :users, only: %i(index)
    end
  end
end
