# frozen_string_literal: true

resque_web_constraint = lambda do |request|
  current_user = request.env['warden'].user
  ability = Ability.new current_user
  rv = ability.present? && ability.respond_to?(:admin?) && ability.admin?
  rv
end

Rails.application.routes.draw do

  mount Blacklight::Engine => '/'

  get '/concern/generic_works/*rest', to: redirect( '/data/concern/data_sets/%{rest}', status: 302 )

  get ':action' => 'hyrax/static#:action', constraints: { action: %r{
                                                                      about|
                                                                      agreement|
                                                                      dbd-documentation-guide|
                                                                      dbd-glossary|
                                                                      file-format-preservation|
                                                                      globus-help|
                                                                      help|
                                                                      how-to-upload|
                                                                      management-plan-text|
                                                                      mendeley|
                                                                      metadata-guidance|
                                                                      prepare-your-data|
                                                                      retention|
                                                                      subject_libraries|
                                                                      support-for-depositors|
                                                                      terms|
                                                                      use-downloaded-data|
                                                                      versions|
                                                                      zotero
                                                                    }x },
      as: :static

  mount Riiif::Engine => 'images', as: :riiif if Hyrax.config.iiif_image_server?
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  devise_for :users, path: '', path_names: {sign_in: 'login', sign_out: 'logout'}, controllers: {sessions: 'sessions'} 
  get '/logout_now', to: 'sessions#logout_now'


  #devise_for :users
  mount Qa::Engine => '/authorities'
  mount Hyrax::Engine, at: '/'
  resources :welcome, only: 'index'
  root 'hyrax/homepage#index'
  curation_concerns_basic_routes
  concern :exportable, Blacklight::Routes::Exportable.new

  namespace :hyrax, path: :concern do
    resources :data_sets do
      member do
        # post   'confirm'
        get    'display_provenance_log'
        get    'doi'
        post   'globus_download'
        post   'globus_add_email'
        get    'globus_add_email'
        delete 'globus_clean_download'
        post   'globus_download_add_email'
        get    'globus_download_add_email'
        post   'globus_download_notify_me'
        get    'globus_download_notify_me'
        post   'identifiers'
        post   'tombstone'
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

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

end
