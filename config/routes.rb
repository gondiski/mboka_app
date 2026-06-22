# config/routes.rb
require "sidekiq/web"

class AdminConstraint
  def matches?(request)
    warden = request.env["warden"]
    return false unless warden&.user
    warden.user.has_role?(:admin)
  end
end

Rails.application.routes.draw do
  # Sidekiq Web UI - admin only
  mount Sidekiq::Web => "/admin/sidekiq", constraints: AdminConstraint.new

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

  # Email Preferences (token-based, unauthenticated)
  get "email_preferences/:token", to: "email_preferences#show", as: :email_preferences
  patch "email_preferences/:token", to: "email_preferences#update"
  get "unsubscribe/:token", to: "email_preferences#unsubscribe", as: :unsubscribe_email

  # Structural Core Views
  get "about",   to: "pages#about",   as: :about
  get "privacy", to: "pages#privacy", as: :privacy
  get "terms",   to: "pages#terms",   as: :terms
  get "health",  to: "pages#health",  as: :health

  # Subscriber Profiles Panel
  resource :profile, only: [ :show, :update ]
  resources :topic_digests, only: [ :show ], path: "digests"
  post "favorites/toggle/:topic_digest_id", to: "favorites#toggle", as: :toggle_favorite

  # Administration Zone Control Arrays
  namespace :admin do
    resource :dashboard, only: [ :show ]
    resource :reports, only: [ :show ]
    resource :settings, only: [ :show, :update ]
    resource :digest_schedule, only: [ :show, :update ]
    get "docs", to: "docs#show", as: :docs

    # Payments
    resource :payments, only: [ :show ] do
      post :checkout
      collection do
        get :verify
        get :history
      end
    end

    resources :digests, only: [ :index, :show, :edit, :update ] do
      member do
        patch :approve
        patch :reject
        patch :reset_to_draft
      end
      collection do
        patch :bulk_approve
      end
    end
    resources :users, only: [ :index, :show ] do
      member do
        patch :update_status
        patch :update_role
      end
      collection do
        post :import
        post :invite
        get :download_template
      end
    end
    resources :invitations, only: [ :create ]
  end

  # Paystack Webhook
  post "webhooks/paystack", to: "webhooks/paystack#receive"

  # Locked Page (app expired)
  get "locked", to: "pages#locked", as: :locked
end
