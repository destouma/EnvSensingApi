Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  # Health check for load balancers and uptime monitors: 200 if the app boots, 500 otherwise.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json }, constraints: { format: :json } do
    namespace :v1 do
      get "time", to: "time#show"

      resources :sensor_types, only: :index

      resources :devices, param: :uuid, only: [:index, :show, :create] do
        resources :sensors, only: [:index, :create]
      end

      resources :sensors, param: :uuid, only: :show do
        resources :readings, only: [:index, :create]
        resources :pictures, only: [:index, :create]
      end

      # Batch of readings for several sensors of the authenticated device
      post "readings", to: "readings#batch", as: :readings_batch

      resources :pictures, only: [] do
        get :file, on: :member
      end
    end
  end
end
