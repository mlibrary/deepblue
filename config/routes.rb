# frozen_string_literal: true

resque_web_constraint = lambda do |request|
  current_user = request.env['warden'].user
  ability = Ability.new current_user
  rv = ability.present? && ability.respond_to?(:admin?) && ability.admin?
  rv
end

Hyrax::Engine.routes.draw do

  get 'contact', to: redirect('https://teamdynamix.umich.edu/TDClient/88/Portal/Requests/TicketRequests/NewForm?ID=90boDMPMEIE_&RequestorType=Service')
  post 'contact', to: redirect('https://teamdynamix.umich.edu/TDClient/88/Portal/Requests/TicketRequests/NewForm?ID=90boDMPMEIE_&RequestorType=Service')

end

Rails.application.routes.draw do
  concern :oai_provider, BlacklightOaiProvider::Routes.new

  mount Blacklight::Engine => '/'
  mount BrowseEverything::Engine => '/browse'

  if '/data' == Settings.relative_url_root
    # note that this path assumes a leading /data
    get '/concern/generic_works/(*rest)', to: redirect( '/data/concern/data_sets/%{rest}', status: 302 )
    get '/metadata-guidance', to: redirect( '/data/depositor-guide#deposit-in-dbd', status: 302 )
    get '/dbd-documentation-guide', to: redirect( '/data/depositor-guide#prepare-documentation', status: 302 )
  elsif '/' == Settings.relative_url_root
    get '/concern/generic_works/(*rest)', to: redirect( '/concern/data_sets/%{rest}', status: 302 )
    get '/metadata-guidance', to: redirect( '/depositor-guide#deposit-in-dbd', status: 302 )
    get '/dbd-documentation-guide', to: redirect( '/depositor-guide#prepare-documentation', status: 302 )
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
  mount Hydra::RoleManagement::Engine => '/'

  get '/logout_now', to: 'sessions#logout_now'

  mount Qa::Engine => '/authorities'
  mount Hyrax::Engine, at: '/'
  mount Samvera::Persona::Engine => '/'
  resources :welcome, only: 'index'
  root 'hyrax/homepage#index'
  curation_concerns_basic_routes
  concern :exportable, Blacklight::Routes::Exportable.new

  # resources :downloads, only: :show # add this to get it working: Rails.application.routes.url_helpers.url_for( only_path: true, action: 'show', controller: 'downloads', id: "id123" )

  get 'anonymous_link/show/:id' => 'hyrax/anonymous_links_viewer#show', as: :show_anonymous_link
  get 'anonymous_link/download/:id' => 'hyrax/anonymous_links_viewer#download'
  post 'anonymous_link/download/:id' => 'hyrax/anonymous_links_viewer#download', as: :download_anonymous_link
  post 'anonymous_link/generate_download/:id' => 'hyrax/anonymous_links#create_anonymous_download', as: :generate_download_anonymous_link
  post 'anonymous_link/generate_show/:id' => 'hyrax/anonymous_links#create_anonymous_show', as: :generate_show_anonymous_link
  get 'anonymous_link/generated/:id' => 'hyrax/anonymous_links#index', as: :generated_anonymous_links
  delete 'anonymous_link/:id/delete/:anon_link_id' => 'hyrax/anonymous_links#destroy', as: :delete_anonymous_link

  post 'single_use_link/download/:id' => 'hyrax/single_use_links_viewer#download', as: :download_single_use_link

  get '/create_draft_doi', controller: 'hyrax_doi', action: 'create_draft_doi', as: 'create_draft_doi'
  get '/autofill', controller: 'hyrax_doi', action: 'autofill', as: 'autofill'

  namespace :hyrax, path: :concern do
    resources :collections do
      member do
        get    'display_provenance_log'
      end
    end
  end

  get  'dashboard/collections/:id/doi', controller: 'hyrax/dashboard/collections', action: :doi
  post 'dashboard/collections/:id/doi', controller: 'hyrax/dashboard/collections', action: :doi

  namespace :hyrax, path: :concern do
    resources :file_sets do
      member do
        get    'assign_to_work_as_read_me'
        post   'create_anonymous_link'
        post   'create_single_use_link'
        get    'display_provenance_log'
        get    'doi'
        post   'doi'
        get    'move_file'
        post   'move_file'
        get    'file_contents'
        get    'anonymous_link/:anon_link_id', action: :anonymous_link
        get    'single_use_link/:link_id', action: :single_use_link
      end
    end
  end

  namespace :hyrax, path: :concern do
    resources :data_sets do
      member do
        get    'analytics_subscribe'
        post   'analytics_subscribe'
        get    'analytics_unsubscribe'
        post   'analytics_unsubscribe'
        get    'aptrust_upload'
        post   'aptrust_upload'
        get    'aptrust_verify'
        post   'aptrust_verify'
        # post   'confirm'
        post   'create_anonymous_link'
        get    'create_service_request'
        post   'create_service_request'
        post   'create_single_use_link'
        get    'display_provenance_log'
        get    'doi'
        post   'doi'
        get    'ensure_doi_minted'
        post   'ensure_doi_minted'
        post   'globus_download'
        post   'globus_add_email'
        get    'globus_add_email'
        delete 'globus_clean_download'
        post   'globus_download_add_email'
        get    'globus_download_add_email'
        post   'globus_download_notify_me'
        get    'globus_download_notify_me'
        get    'globus_download_redirect'
        get    'ingest_append_script_prep'
        post   'ingest_append_script_prep'
        get    'ingest_append_script_delete'
        post   'ingest_append_script_delete'
        get    'ingest_append_script_generate'
        post   'ingest_append_script_generate'
        get    'ingest_append_script_restart'
        post   'ingest_append_script_restart'
        post   'ingest_append_script_run_job'
        get    'ingest_append_script_view'
        post   'ingest_append_script_view'
        post   'identifiers'
        get    'anonymous_link/:anon_link_id', action: :anonymous_link
        get    'anonymous_link_zip_download/:anon_link_id', action: :anonymous_link_zip_download
        get    'single_use_link/:link_id', action: :single_use_link
        get    'single_use_link_zip_download/:link_id', action: :single_use_link_zip_download
        post   'tombstone'
        get    'work_find_and_fix'
        post   'work_find_and_fix'
        get    'zip_download'
        post   'zip_download'
        get    'csv_download', controller: 'stats', action: :csv_download
        post   'csv_download', controller: 'stats', action: :csv_download
      end
    end
  end

  # replacements for hyrax_orcid_routes. --> Rails.application.routes.url_helpers.
  # https://testing.deepblue.lib.umich.edu/data/dashboard/orcid_identity/new?code=EXqQ7S
  get 'dashboard/orcid_identity/new', controller: 'hyrax/orcid/dashboard/orcid_identities', action: :new
  get 'orcid/identities/', controller: 'hyrax/orcid/dashboard/orcid_identities', action: :new, as: 'new_orcid_identity'
  get 'orcid/users/show/:orcid_id', controller: 'hyrax/orcid/users', action: :show #, as: 'orcid_identity'
  delete 'orcid/users/:id', controller: 'hyrax/orcid/dashboard/orcid_identities', action: :destroy
  patch 'orcid/users/:id', controller: 'hyrax/orcid/dashboard/orcid_identities', action: :update
  get 'orcid/users/:orcid_id', controller: 'hyrax/orcid/users', action: :show, as: 'orcid_identity'
  get 'orcid/users/profile/:orcid_id', controller: 'hyrax/orcid/users', action: :show, as: 'users_orcid_profile'
  get 'orcid/works/publish/:work_id/:orcid_id', controller: 'hyrax/orcid/dashboard/works', action: :publish, as: 'orcid_works_publish'
  get 'orcid/works/unpublish/:work_id/:orcid_id', controller: 'hyrax/orcid/dashboard/works', action: :unpublish, as: 'orcid_works_unpublish'

  mount WillowSword::Engine => '/sword'

  # Permissions routes
  namespace :hyrax, path: :concern do
  resources :permissions, only: [] do
      member do
        get :copy_access
      end
    end
  end

  resources :works, only: [] do
    member do
      resource :featured_work, only: [:create, :destroy]
    end
  end

  #resource :featured_work, only: [] do
    get '/works/:id/featured_work', controller: 'hyrax/featured_works', action: :index
  #end

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

  get '/debug_log_dashboard/' => 'debug_log_dashboard#show'
  post '/debug_log_dashboard/' => 'debug_log_dashboard#show'
  get '/debug_log_dashboard_action/' => 'debug_log_dashboard#action'
  post '/debug_log_dashboard_action/' => 'debug_log_dashboard#action'
  get '/contact_form_dashboard/' => 'contact_form_dashboard#show'
  post '/contact_form_dashboard/' => 'contact_form_dashboard#show'
  get '/contact_form_dashboard_action/' => 'contact_form_dashboard#action'
  post '/contact_form_dashboard_action/' => 'contact_form_dashboard#action'
  get '/email_dashboard/' => 'email_dashboard#show'
  post '/email_dashboard/' => 'email_dashboard#show'
  get '/email_dashboard_action/' => 'email_dashboard#action'
  get '/email_dashboard_resend/' => 'email_dashboard#resend'
  post '/email_dashboard_resend/' => 'email_dashboard#resend'
  get '/email_dashboard_show/' => 'email_dashboard#show'
  post '/email_dashboard_show/' => 'email_dashboard#show'
  get '/globus_dashboard/' => 'globus_dashboard#show'
  get '/globus_dashboard_run_action/' => 'globus_dashboard#run_action'
  post '/globus_dashboard_run_action/' => 'globus_dashboard#run_action'
  get '/google_analytics_dashboard/' => 'google_analytics_dashboard#show'
  get '/guest_user_message', to: 'guest_user_message#show'
  get '/ingest_dashboard/' => 'ingest_dashboard#show'
  get '/ingest_dashboard_run_ingests_job/' => 'ingest_dashboard#run_ingests_job'
  post '/ingest_dashboard_run_ingests_job/' => 'ingest_dashboard#run_ingests_job'
  get '/provenance_log/(:id)', to: 'provenance_log#show'
  get '/provenance_log/', to: 'provenance_log#show'
  get '/provenance_log_find/', to: 'provenance_log#show'
  post '/provenance_log_find/', to: 'provenance_log#find'
  get '/provenance_log_zip_download/', to: 'provenance_log#show'
  post '/provenance_log_zip_download/', to: 'provenance_log#log_zip_download'
  get '/provenance_log_deleted_works/', to: 'provenance_log#deleted_works'
  post '/provenance_log_deleted_works/', to: 'provenance_log#deleted_works'
  get '/provenance_log_works_by_user_id/', to: 'provenance_log#works_by_user_id'
  post '/provenance_log_works_by_user_id/', to: 'provenance_log#works_by_user_id'
  get '/report_dashboard/' => 'report_dashboard#show'
  get '/report_dashboard_run_action/' => 'report_dashboard#run_action'
  post '/report_dashboard_run_action/' => 'report_dashboard#run_action'
  get '/scheduler_dashboard/' => 'scheduler_dashboard#show'
  get '/scheduler_dashboard_action/' => 'scheduler_dashboard#action'
  post '/scheduler_dashboard_action/' => 'scheduler_dashboard#action'
  # get '/scheduler_dashboard_run_job/' => 'scheduler_dashboard#run_job'
  # post '/scheduler_dashboard_run_job/' => 'scheduler_dashboard#run_job'
  get '/scheduler_dashboard_job_action/' => 'scheduler_dashboard#job_action'
  post '/scheduler_dashboard_job_action/' => 'scheduler_dashboard#job_action'
  # get '/scheduler_dashboard_subscribe/' => 'scheduler_dashboard#subscribe'
  # post '/scheduler_dashboard_subscribe/' => 'scheduler_dashboard#subscribe'
  get '/scheduler_dashboard_update_schedule/' => 'scheduler_dashboard#update_schedule'
  post '/scheduler_dashboard_update_schedule/' => 'scheduler_dashboard#update_schedule'
  get '/work_view_content/:id/:file_id' => 'work_view_content#show', constraint: { id: /[^\/]+/, file_id: /[^\/]+/ }
  get '/work_view_documentation/' => 'work_view_documentation#show'
  get '/work_view_documentation_action/' => 'work_view_documentation#action'
  post '/work_view_documentation_action/' => 'work_view_documentation#action'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # mount Yabeda::Prometheus::Exporter => "/metrics"

  resource :email_subscription
  get 'email_subscriptions', to: 'email_subscriptions#index', as: 'email_subscriptions' # index

  resource :aptrust_event
  get 'aptrust_events', controller: 'aptrust/aptrust_events', action: :index
  post 'aptrust_events', controller: 'aptrust/aptrust_events', action: :index

  resource :aptrust_status
  get 'aptrust_statuses', controller: 'aptrust/aptrust_statuses', action: :index
  post 'aptrust_statuses', controller: 'aptrust/aptrust_statuses', action: :index
  get '/aptrust_status_action/', controller: 'aptrust/aptrust_statuses', action: :status_action
  post '/aptrust_status_action/', controller: 'aptrust/aptrust_statuses', action: :status_action
  # put 'aptrust_statuses', to: 'aptrust_statuses#index' #, as: 'aptrust_statuses' # index
  # get '/aptrust_statuses_failed/' => 'aptrust_statuses#status_failed'
  # get '/aptrust_statuses_finished/' => 'aptrust_statuses#status_finished'
  # get '/aptrust_statuses_has_error/' => 'aptrust_statuses#has_error'
  # get '/aptrust_statuses_not_finished/' => 'aptrust_statuses#status_not_finished'
  # get '/aptrust_statuses_started/' => 'aptrust_statuses#status_started'

  get 'job_workers', to: 'job_workers#index', as: 'job_workers' # index
  put 'job_workers', to: 'job_workers#index' #, as: 'job_workers' # index
  # get '/job_statuses_failed/' => 'job_statuses#status_failed'

  # resource :job_status #, only: [:index, :show, :update]
  resource :job_status
  get 'job_statuses', to: 'job_statuses#index', as: 'job_statuses' # index
  post 'job_statuses', to: 'job_statuses#index' #, as: 'job_statuses' # index
  put 'job_statuses', to: 'job_statuses#index' #, as: 'job_statuses' # index
  get '/job_statuses_failed/' => 'job_statuses#status_failed'
  get '/job_statuses_finished/' => 'job_statuses#status_finished'
  get '/job_statuses_has_error/' => 'job_statuses#has_error'
  get '/job_statuses_not_finished/' => 'job_statuses#status_not_finished'
  get '/job_statuses_started/' => 'job_statuses#status_started'

  get  '/my/works/analytics_subscribe', controller: 'hyrax/my/works', action: :analytics_subscribe
  post '/my/works/analytics_subscribe', controller: 'hyrax/my/works', action: :analytics_subscribe
  get  '/my/works/analytics_unsubscribe', controller: 'hyrax/my/works', action: :analytics_unsubscribe
  post '/my/works/analytics_unsubscribe', controller: 'hyrax/my/works', action: :analytics_unsubscribe

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
