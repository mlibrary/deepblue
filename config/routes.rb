# frozen_string_literal: true

resque_web_constraint = lambda do |request|
  current_user = request.env['warden'].user
  ability = Ability.new current_user
  rv = ability.present? && ability.respond_to?(:admin?) && ability.admin?
  rv
end

Rails.application.routes.draw do
  concern :oai_provider, BlacklightOaiProvider::Routes.new


  mount Blacklight::Engine => '/'
  mount BrowseEverything::Engine => '/browse'

  if '/data' == Settings.relative_url_root
    # note that this path assumes a leading /data
    get '/concern/generic_works/(*rest)', to: redirect( '/data/concern/data_sets/%{rest}', status: 302 )
  elsif '/' == Settings.relative_url_root
    get '/concern/generic_works/(*rest)', to: redirect( '/concern/data_sets/%{rest}', status: 302 )
  end

  get 'static/show/:layout/:doc/:file', to: 'hyrax/static#show_layout_doc'
  get 'static/show/:doc/:file', to: 'hyrax/static#show_doc'


  get ':doc', to: 'hyrax/static#show', constraints: { doc: %r{
                                                                      about|
                                                                      about-top|
                                                                      agreement|
                                                                      dbd-glossary|
                                                                      depositor-guide|
                                                                      faq|
                                                                      help|
                                                                      globus-help|
                                                                      rest-api|
                                                                      services|
                                                                      user-guide|
                                                                      delete-to-here|
                                                                      mendeley|
                                                                      zotero
                                                                    }x },
      as: :static

  # dbd-documentation-guide|
  #     file-format-preservation|
  #     globus-help|
  #     how-to-upload|
  #     management-plan-text|
  #     metadata-guidance|
  #     prepare-your-data|
  #     retention|
  #     subject_libraries|
  #     support-for-depositors|
  #         terms|
  #         use-downloaded-data|
  #         versions|


  # get ':action' => 'hyrax/static#:action', constraints: { action: %r{
  #                                                                     about|
  #                                                                     agreement|
  #                                                                     dbd-documentation-guide|
  #                                                                     dbd-glossary|
  #                                                                     file-format-preservation|
  #                                                                     globus-help|
  #                                                                     help|
  #                                                                     how-to-upload|
  #                                                                     management-plan-text|
  #                                                                     mendeley|
  #                                                                     metadata-guidance|
  #                                                                     prepare-your-data|
  #                                                                     retention|
  #                                                                     subject_libraries|
  #                                                                     support-for-depositors|
  #                                                                     terms|
  #                                                                     use-downloaded-data|
  #                                                                     versions|
  #                                                                     zotero
  #                                                                   }x },
  #     as: :static

  mount Riiif::Engine => 'images', as: :riiif if Hyrax.config.iiif_image_server?
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :oai_provider

    concerns :searchable
  end


  if Rails.configuration.authentication_method == "umich"
    devise_for :users, path: '', path_names: {sign_in: 'login', sign_out: 'logout'}, controllers: {sessions: 'sessions'}
  elsif Rails.configuration.authentication_method == "iu"
    devise_for :users, controllers: { sessions: 'users/sessions', omniauth_callbacks: "users/omniauth_callbacks" }, skip: [:passwords, :registration]
    devise_scope :user do
      get('global_sign_out',
          to: 'users/sessions#global_logout',
          as: :destroy_global_session)
      get 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
      get 'users/auth/cas', to: 'users/omniauth_authorize#passthru', defaults: { provider: :cas }, as: "new_user_session"
    end
  else
    devise_for :users
  end

  get '/logout_now', to: 'sessions#logout_now'

  mount Qa::Engine => '/authorities'
  mount Hyrax::Engine, at: '/'
  mount Samvera::Persona::Engine => '/'
  resources :welcome, only: 'index'
  root 'hyrax/homepage#index'
  curation_concerns_basic_routes
  concern :exportable, Blacklight::Routes::Exportable.new

  # resources :downloads, only: :show # add this to get it working: Rails.application.routes.url_helpers.url_for( only_path: true, action: 'show', controller: 'downloads', id: "id123" )
  #
  # get 'single_use_link/show/:id' => 'single_use_links_viewer#show', as: :show_single_use_link
  # get 'single_use_link/download/:id' => 'single_use_links_viewer#download', as: :download_single_use_link
  # post 'single_use_link/generate_download/:id' => 'single_use_links#create_download', as: :generate_download_single_use_link
  # post 'single_use_link/generate_show/:id' => 'single_use_links#create_show', as: :generate_show_single_use_link
  # get 'single_use_link/generated/:id' => 'single_use_links#index', as: :generated_single_use_links
  # delete 'single_use_link/:id/delete/:link_id' => 'single_use_links#destroy', as: :delete_single_use_link

  # post 'single_use_link/generate_zip_download/:id' => 'single_use_links#create_zip_download', as: :generate_zip_download_single_use_link

  post 'single_use_link/download/:id' => 'hyrax/single_use_links_viewer#download', as: :download_single_use_link

  namespace :hyrax, path: :concern do
    resources :collections do
      member do
        get    'display_provenance_log'
      end
    end
  end

  namespace :hyrax, path: :concern do
    resources :file_sets do
      member do
        post   'create_single_use_link'
        get    'display_provenance_log'
        get    'doi'
        post   'doi'
        get    'file_contents'
        get    'single_use_link/:link_id', action: :single_use_link
      end
    end
  end

  namespace :hyrax, path: :concern do
    resources :data_sets do
      member do
        # post   'confirm'
        post   'create_single_use_link'
        get    'display_provenance_log'
        get    'doi'
        post   'doi'
        post   'globus_download'
        post   'globus_add_email'
        get    'globus_add_email'
        delete 'globus_clean_download'
        post   'globus_download_add_email'
        get    'globus_download_add_email'
        post   'globus_download_notify_me'
        get    'globus_download_notify_me'
        get    'ingest_append_generate_script'
        post   'ingest_append_generate_script'
        get    'ingest_append_prep'
        post   'ingest_append_prep'
        post   'ingest_append_run_job'
        post   'identifiers'
        get    'single_use_link/:link_id', action: :single_use_link
        get    'single_use_link_zip_download/:link_id', action: :single_use_link_zip_download
        post   'tombstone'
        get    'zip_download'
        post   'zip_download'
      end
    end
  end

  # Permissions routes
  namespace :hyrax, path: :concern do
  resources :permissions, only: [] do
      member do
        get :copy_access
      end
    end
  end

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  constraints resque_web_constraint do
    mount ResqueWeb::Engine => "/resque"
  end

  resources :bookmarks do
    concerns :exportable
    collection do
      delete 'clear'
    end
  end

  get '/email_dashboard/' => 'email_dashboard#show'
  get '/email_dashboard_action/' => 'email_dashboard#action'
  get '/google_analytics_dashboard/' => 'google_analytics_dashboard#show'
  get '/guest_user_message', to: 'guest_user_message#show'
  get '/provenance_log/(:id)', to: 'provenance_log#show'
  get '/provenance_log_find/', to: 'provenance_log#show'
  post '/provenance_log_find/', to: 'provenance_log#find'
  get '/provenance_log_zip_download/', to: 'provenance_log#show'
  post '/provenance_log_zip_download/', to: 'provenance_log#log_zip_download'
  get '/provenance_log_deleted_works/', to: 'provenance_log#deleted_works'
  post '/provenance_log_deleted_works/', to: 'provenance_log#deleted_works'
  get '/scheduler_dashboard/' => 'scheduler_dashboard#show'
  get '/scheduler_dashboard_action/' => 'scheduler_dashboard#action'
  post '/scheduler_dashboard_action/' => 'scheduler_dashboard#action'
  get '/scheduler_dashboard_update_schedule/' => 'scheduler_dashboard#update_schedule'
  post '/scheduler_dashboard_update_schedule/' => 'scheduler_dashboard#update_schedule'
  get '/work_view_content/:id/:file_id' => 'work_view_content#show', constraint: { id: /[^\/]+/, file_id: /[^\/]+/ }
  get '/work_view_documentation/' => 'work_view_documentation#show'
  get '/work_view_documentation_action/' => 'work_view_documentation#action'
  post '/work_view_documentation_action/' => 'work_view_documentation#action'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

end

# # Match IDs with dots in them
# id_pattern = /[^\/]+/
#
# ResqueWeb::Engine.routes.draw do
#   scope '/data' do
#   ResqueWeb::Plugins.plugins.each do |p|
#     mount p::Engine => p.engine_path
#   end
#
#   resource  :overview,  :only => [:show], :controller => :overview
#   resources :working,   :only => [:index]
#   resources :queues,    :only => [:index,:show,:destroy], :constraints => {:id => id_pattern} do
#     member do
#       put 'clear'
#     end
#   end
#   resources :workers,   :only => [:index,:show], :constraints => {:id => id_pattern}
#   resources :failures,  :only => [:show,:index,:destroy] do
#     member do
#       put 'retry'
#     end
#     collection do
#       put 'retry_all'
#       delete 'destroy_all'
#     end
#   end
#
#   get '/stats' => 'stats#index'
#   get '/stats/resque' => 'stats#resque'
#   get '/stats/redis' => 'stats#redis'
#   get '/stats/keys' => 'stats#keys'
#   get '/stats/keys/:id' => 'stats#keys', :constraints => { :id => id_pattern }, as: :keys_statistic
#
#   root :to => 'overview#show'
#   end
# end
