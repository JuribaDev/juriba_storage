Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  namespace :api do
    namespace :v1 do
      # Authentication routes
      post "login", to: "authentication#login"
      # Blob routes
      resources :blobs, only: [ :create, :show ], param: :id do
        collection do
          get :generate_uuid
        end
      end
    end
    get "/up", to: proc { [ 200, {}, [ "OK" ] ] }
  end
end
