Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :api, constraints: { format: 'json' }, defaults: { format: 'json' } do
    namespace :v1 do

      resources :devices do
        collection do
          get :index
        end
      end

      resources :sensors do
        collection do
          get :index
        end
      end

      resources :sensor_readings do
        collection do
          get :index
          post :create
        end
      end

      resources :sensor_types do
        collection do
          get :index
        end
      end

      resources :date_time do
        collection do
          get :current_date_time
        end
      end

      resources :pictures do
        collection do
          get :index
          post :create
          post :upload
          get :file
        end
      end

    end
  end
end
