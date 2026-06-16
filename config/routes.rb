# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, skip: [ :sessions, :registrations ]

  # Passwordless Authentication Interface
  as :user do
    get    "login",          to: "magic_links#new",       as: :new_user_session
    post   "magic_links",    to: "magic_links#create",    as: :magic_links
    get    "magic_links/v",  to: "magic_links#validate",  as: :validate_magic_link
    delete "logout",         to: "devise/sessions#destroy", as: :destroy_user_session
  end

  # Public Access Points & Intake Channels
  root "subscribers#new"
  resources :subscribers, only: [ :create ]
  get "check_email", to: "magic_links#check_email", as: :check_email

  # Structural Core Views
  get "about",   to: "pages#about",   as: :about
  get "privacy", to: "pages#privacy", as: :privacy
  get "terms",   to: "pages#terms",   as: :terms

  # Subscriber Profiles Panel
  resource :profile, only: [ :show, :update ]

  # Administration Zone Control Arrays
  namespace :admin do
    resource :dashboard, only: [ :show ]
    resource :digest_schedule, only: [ :show, :update ]
    resources :users, only: [ :index ] do
      member do
        patch :update_status
      end
      collection do
        post :import
      end
    end
  end
end
