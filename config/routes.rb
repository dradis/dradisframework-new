if ENV['RAILS_RELATIVE_URL_ROOT']
  Rails.application.routes.default_scope = ENV['RAILS_RELATIVE_URL_ROOT']
end

Rails.application.routes.draw do
  get 'up', to: ->(env) { [204, {}, ['']] }

  # ------------------------------------------------------------ Authentication
  # Sign in / sign out
  get '/login'  => 'sessions#new'
  get '/logout' => 'sessions#destroy'
  resource :session

  resources :comments

  # ------------------------------------------------------------ Project routes
  concern :multiple_destroy do
    collection do
      delete :multiple_destroy
    end
  end

  concern :multiple_update do
    collection do
      patch :multiple_update
    end
  end

  concern :previewable do
    member do
      post :preview
    end
  end

  resources :notifications, only: [:index, :update]

  resources :projects, only: [:index, :show] do
    resources :activities, only: [:index] do
      collection do
        get :poll, constraints: { format: /js/ }
      end
    end

    resources :boards do
      resources :lists, except: [:index] do
        member { post :move }
        resources :cards, except: [:index] do
          member { post :move }
          resources :revisions, only: [:index, :show]
        end
      end
    end

    constraints id: %r{[(0-z)\/]+} do
      resources :configurations, only: [:index, :update]
    end

    post :create_multiple_evidence, to: 'issues/evidence#create_multiple'

    resources :issues, concerns: [:multiple_destroy, :previewable] do
      collection do
        post :import
        resources :merge, only: [:new, :create], controller: 'issues/merge'
      end

      resources :evidence, concerns: :multiple_destroy, controller: 'issues/evidence', only: [:index, :new]
      resources :nodes, only: [:show], controller: 'issues/nodes'
      resources :revisions, only: [:index, :show]
    end

    resources :methodologies do
      collection { post :preview }
      member do
        get :add
        put :update_task
      end
    end

    resources :nodes do
      collection do
        post :sort
        post :create_multiple
      end

      member do
        get :tree
      end

      resource :merge, only: [:create], controller: 'nodes/merge'

      resources :notes, concerns: [:multiple_destroy, :previewable] do
        resources :revisions, only: [:index, :show]
      end

      resources :evidence, except: :index, concerns: [:multiple_destroy, :previewable] do
        resources :revisions, only: [:index, :show]
      end

      constraints(filename: /.*/) do
        resources :attachments, only: [:index, :show, :create, :destroy], param: :filename
      end
    end

    resources :notifications, only: [:index, :update]

    resources :revisions, only: [] do
      member { post :recover }
    end

    resources :tags, except: [:show]

    resources :tasks, only: :index

    namespace :qa do
      resources :issues, only: [:edit, :index, :show, :update], concerns: [:multiple_update, :previewable]
    end

    get 'search' => 'search#index'
    get 'trash' => 'revisions#trash'

    # ------------------------------------------------------- Export Manager
    get  '/export' => 'export#index', as: :export_manager

    # ------------------------------------------------------- Upload Manager
    get  '/upload'        => 'upload#index',  as: :upload_manager
    post '/upload'        => 'upload#create'
    post '/upload/parse'  => 'upload#parse'

    if Rails.env.development?
      get '/styles' => 'styles_tylium#index'
    end
  end

  resources :console, only: [] do
    collection { get :status }
  end

  resource :fields, only: [] do
    collection do
      get :field
      post :form
      post :source
    end
  end

  namespace :setup, only: [:index] do
    if defined?(Dradis::Pro)
    else
      resource :password, only: [:new, :create]
    end
    resource :kit, only: [:new, :create]
  end

  resources :subscriptions, only: [:index, :create, :destroy]

  # -------------------------------------------------------------- Static pages
  resource :markup, controller: :markup, only: [] do
    get :help
    post :preview
  end

  if defined?(Dradis::Pro)
  else
    root to: 'setup/passwords#new'
  end

  mount ActionCable.server => '/cable'
end
