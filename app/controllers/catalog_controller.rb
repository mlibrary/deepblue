# frozen_string_literal: true
# Reviewed: heliotrope
# Reviewed: hyrax4 -- .dassie

class CatalogController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior
  include BlacklightOaiProvider::Controller

  mattr_accessor :catalog_controller_debug_verbose, default: Rails.configuration.catalog_controller_debug_verbose
  mattr_accessor :catalog_controller_allow_search_fix_for_json, default: true

  # This filter applies the hydra access controls
  before_action :enforce_show_permissions, only: :show

  def self.uploaded_field
    "system_create_dtsi"
  end

  def self.modified_field
    "system_modified_dtsi"
  end

  def self.configure_facet_fields( config )
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "config.class.name=#{config.class.name}",
    #                                        "" ] if catalog_controller_debug_verbose

    @@facet_solr_name_to_name = {}
    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    { "resource_type" => "Resource Type",
      "creator" => "Creator",
      "subject_discipline" => "Discipline",
      "language" => "Language" }.each_pair do |name,label|

      facet_solr_name = solr_name(name, :facetable)
      config.add_facet_field( facet_solr_name, label: label, limit: 5 )
      @@facet_solr_name_to_name[facet_solr_name.to_s] = name
    end
    # generic_type is a special case
    name = "generic_type"
    facet_solr_name = solr_name(name, :facetable)
    @@facet_solr_name_to_name[facet_solr_name.to_s] = name
  end

  def self.facet_solr_name_to_name( facet_solr_name )
    @@facet_solr_name_to_name[facet_solr_name]
  end

  configure_blacklight do |config| # rubocop:disable Metrics/BlockLength
    config.view.gallery(document_component: Blacklight::Gallery::DocumentComponent)
    config.view.masonry(document_component: Blacklight::Gallery::DocumentComponent)
    config.view.slideshow(document_component: Blacklight::Gallery::SlideshowComponent)

    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)
    # which of thesee? # config.search_builder_class = ::SearchBuilder
    config.search_builder_class = Hyrax::CatalogSearchBuilder

    # set maximum results per page to support bootstrap page sorting
    # in dashboard.
    # config.max_per_page = 1000000

    # Show gallery view
    # hyrax2 # config.view.gallery.partials = %i[index_header index]
    # hyrax2 # config.view.slideshow.partials = [:index]

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 10,
      qf: "title_tesim name_tesim creator_tesim caption_tesim description_tesim grantnumber_tesim methodology_tesim subject_tesim keyword_tesim referenced_by_tesim all_text_timv"
    }

    # solr field configuration for document/show views
    config.index.title_field = "title_tesim"
    config.index.display_type_field = "has_model_ssim"
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr field configuration for document/show views
    # config.show.title_field = solr_name("title", :stored_searchable)
    # config.show.display_type_field = solr_name("has_model", :symbol)

    # hyrax2 # configure_facet_fields( config )

    # The generic_type isn't displayed on the facet list
    # It's used to give a label to the filter that comes from the user profile
    # hyrax2 # config.add_facet_field solr_name('generic_type', :facetable), if: false

    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)
    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)
    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field "human_readable_type_sim", label: "Type", limit: 5
    config.add_facet_field "resource_type_sim", label: "Resource Type", limit: 5
    config.add_facet_field "creator_sim", limit: 5
    config.add_facet_field "contributor_sim", label: "Contributor", limit: 5
    config.add_facet_field "keyword_sim", limit: 5
    config.add_facet_field "subject_sim", limit: 5
    config.add_facet_field "language_sim", limit: 5
    config.add_facet_field "based_near_label_sim", limit: 5
    config.add_facet_field "publisher_sim", limit: 5
    config.add_facet_field "file_format_sim", limit: 5
    config.add_facet_field "member_of_collection_ids_ssim", limit: 5, label: 'Collections', helper_method: :collection_title_by_id

    # The generic_type and depositor are not displayed on the facet list
    # They are used to give a label to the filters that comes from the user profile
    config.add_facet_field "generic_type_sim", if: false
    config.add_facet_field "depositor_ssim", label: "Depositor", if: false

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    # hyrax2 # config.add_index_field solr_name("title", :stored_sortable, type: :string), label: "Title" #To be able to sort by title
    config.add_index_field "title_tesim", label: "Title", itemprop: 'name', if: false
    config.add_index_field "description_tesim", itemprop: 'description', helper_method: :iconify_auto_link
    config.add_index_field "keyword_tesim", itemprop: 'keywords', link_to_facet: "keyword_sim"
    config.add_index_field "subject_tesim", itemprop: 'about', link_to_facet: "subject_sim"
    config.add_index_field "creator_tesim", itemprop: 'creator', link_to_facet: "creator_sim"
    config.add_index_field "contributor_tesim", itemprop: 'contributor', link_to_facet: "contributor_sim"
    config.add_index_field "proxy_depositor_ssim", label: "Depositor", helper_method: :link_to_profile
    config.add_index_field "depositor_tesim", label: "Owner", helper_method: :link_to_profile
    config.add_index_field "publisher_tesim", itemprop: 'publisher', link_to_facet: "publisher_sim"
    config.add_index_field "based_near_label_tesim", itemprop: 'contentLocation', link_to_facet: "based_near_label_sim"
    config.add_index_field "language_tesim", itemprop: 'inLanguage', link_to_facet: "language_sim"
    config.add_index_field "date_uploaded_dtsi", itemprop: 'datePublished', helper_method: :human_readable_date
    config.add_index_field "date_modified_dtsi", itemprop: 'dateModified', helper_method: :human_readable_date
    config.add_index_field "date_created_tesim", itemprop: 'dateCreated'
    config.add_index_field "rights_statement_tesim", helper_method: :rights_statement_links
    config.add_index_field "license_tesim", helper_method: :license_links
    config.add_index_field "resource_type_tesim", label: "Resource Type", link_to_facet: "resource_type_sim"
    config.add_index_field "file_format_tesim", link_to_facet: "file_format_sim"
    config.add_index_field "identifier_tesim", helper_method: :index_field_link, field_name: 'identifier'
    config.add_index_field Hydra.config.permissions.embargo.release_date, label: "Embargo release date", helper_method: :human_readable_date
    config.add_index_field Hydra.config.permissions.lease.expiration_date, label: "Lease expiration date", helper_method: :human_readable_date
    config.add_index_field solr_name('referenced_by', :stored_searchable), itemprop: 'referenced_by', label: "Citation to related publication", helper_method: :iconify_auto_link
    config.add_index_field solr_name('subject_discipline', :stored_searchable), itemprop: 'subject_discipline', label: "Discipline", link_to_search: solr_name("subject_discipline", :facetable)

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field "title_tesim"
    config.add_show_field "description_tesim"
    config.add_show_field "keyword_tesim"
    config.add_show_field "subject_tesim"
    config.add_show_field solr_name('subject_discipline', :stored_searchable)
    config.add_show_field "creator_tesim"
    config.add_show_field solr_name('creator_orcid', :stored_searchable)
    config.add_show_field "contributor_tesim"
    config.add_show_field solr_name('depositor_creator', :stored_searchable)
    config.add_show_field "publisher_tesim"
    config.add_show_field "based_near_label_tesim"
    config.add_show_field "language_tesim"
    config.add_show_field "date_uploaded_tesim"
    config.add_show_field "date_modified_tesim"
    config.add_show_field "date_created_tesim"
    config.add_show_field "rights_statement_tesim"
    config.add_show_field "license_tesim"
    config.add_show_field "resource_type_tesim", label: "Resource Type"
    config.add_show_field "format_tesim"
    config.add_show_field "identifier_tesim"
    config.add_show_field solr_name('date_published', :stored_searchable), label: "Published"
    config.add_show_field 'date_published_dtsim'
    config.add_show_field solr_name('rights_license', :stored_searchable)
    config.add_show_field 'total_file_size_lts'
    config.add_show_field solr_name('referenced_by', :stored_searchable), label: "Citation to related publication"

    config.add_show_field solr_name('date_coverage', :stored_searchable), label: "Date Coverage"

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields') do |field|
      all_names = config.show_fields.values.map(&:field).join(" ")
      title_name = "title_tesim"
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim all_text_timv",
        pf: title_name.to_s
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('contributor') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = "contributor_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      solr_name = "creator_tesim"
      # hyrax2 # solr_name = solr_name('creator_full_name', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('title') do |field|
      solr_name = "title_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator_orcid') do |field|
      solr_name = solr_name('creator_orcid', :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.label = "Abstract or Summary"
      solr_name = "description_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('description_file_set') do |field|
      field.label = "Description (file set)"
      solr_name = solr_name("description_file_set", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('doi') do |field|
      field.label = "Doi"
      solr_name = solr_name("doi_label", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('fundedby') do |field|
      field.label = "Funded By"
      solr_name = solr_name("fundedby_label", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('access_deepblue') do |field|
      field.label = MsgHelper.t( 'simple_form.labels.data_set.access_deepblue' )
      solr_name = solr_name("access_deepblue_label", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('fundedby_other') do |field|
      field.label = "Funded By Other"
      solr_name = solr_name("fundedby_other_label", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('grantnumber') do |field|
      field.label = "Grant number"
      solr_name = solr_name("grantnumber_label", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('publisher') do |field|
      solr_name = "publisher_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date_created') do |field|
      solr_name = "created_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      solr_name = "subject_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      solr_name = "language_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_type') do |field|
      solr_name = "resource_type_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format') do |field|
      solr_name = "format_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier') do |field|
      solr_name = "id_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('based_near') do |field|
      field.label = "Location"
      solr_name = "based_near_label_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('keyword') do |field|
      solr_name = "keyword_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      solr_name = "depositor_ssim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor_creator') do |field|
      solr_name = solr_name("depositor_creator", :symbol)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_statement') do |field|
      solr_name = "rights_statement_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('license') do |field|
      solr_name = "license_tesim"
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('methodology') do |field|
      field.label = "Methodology"
      solr_name = solr_name("methodology_label", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('prior_identifier') do |field|
      field.label = "Prior Identifier"
      solr_name = solr_name("prior_identifier", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('referenced_by') do |field|
      field.label = "Citation to related publication"
      solr_name = solr_name("referenced_by", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('rights_license') do |field|
      solr_name = solr_name("rights_license", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights_license_other') do |field|
      solr_name = solr_name("rights_license_other", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('subject_discipline') do |field|
      solr_name = solr_name("subject_discipline", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('total_file_size') do |field|
      solr_name = solr_name("total_file_size", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance"
    # config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    # config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    # config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    # config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"
    config.add_sort_field "#{uploaded_field} desc", label: "date created \u25BC"
    config.add_sort_field "#{uploaded_field} asc", label: "date created \u25B2"
    config.add_sort_field "#{modified_field} desc", label: "last modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "last modified \u25B2"

    # Need to reindex the collection to be able to use these.
    config.add_sort_field "title_sort_ssi asc", label: 'title [A-Z]'
    config.add_sort_field "title_sort_ssi desc", label: 'title [Z-A]'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Oai Configuration
    config.oai = {
      provider: {
        repository_name: 'Deep Blue Data',
        repository_url: "https://deepblue.lib.umich.edu#{Rails.configuration.relative_url_root}/catalog/oai", # monkey: Rails.configuration.relative_url_root
        record_prefix: 'oai:deepbluedata',
        admin_email: 'researchdataservices@umich.edu',
        sample_id: '9s1616317'
      },
      document: {
        limit: 50,
        set_model: AdminsetSet,
        set_fields: [{ label: 'admin_set', solr_field: 'admin_set_sim' }]
      }
    }

  end

  # def facet
  #   super
  # rescue Exception => e # rubocop:disable Lint/RescueException
  #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
  #                                          ::Deepblue::LoggingHelper.called_from ] + e.backtrace
  #   raise
  # end
  #
  # def invalid_document_id_error(exception)
  #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
  #                                        ::Deepblue::LoggingHelper.called_from ] + e.backtrace
  #   super(exception)
  # end

  # disable the bookmark control from displaying in gallery view
  # Hyrax doesn't show any of the default controls on the list view, so
  # this method is not called in that context.
  def render_bookmarks_control?
    false
  end
end
