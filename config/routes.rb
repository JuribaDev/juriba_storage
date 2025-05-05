Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Authentication routes
      post "login", to: "authentication#login"
      post "refresh", to: "authentication#refresh"
      delete "logout", to: "authentication#logout"
    end
  end
end
