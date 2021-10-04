# frozen_string_literal: true

class CatalogController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior
  include BlacklightOaiProvider::Controller

  mattr_accessor :catalog_controller_debug_verbose, default: Rails.configuration.catalog_controller_debug_verbose
  mattr_accessor :catalog_controller_allow_search_fix_for_json, default: true

  # This filter applies the hydra access controls
  before_action :enforce_show_permissions, only: :show

  def self.uploaded_field
    solr_name('system_create', :stored_sortable, type: :date)
  end

  def self.modified_field
    solr_name('system_modified', :stored_sortable, type: :date)
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

  configure_blacklight do |config|

    # Oai Configuration
    config.oai = {
      provider: {
        repository_name: 'Deep Blue Data',
        repository_url: "https://deepblue.lib.umich.edu#{::DeepBlueDocs::Application.config.relative_url_root}/catalog/oai", # monkey: ::DeepBlueDocs::Application.config.relative_url_root
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


    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "config.class.name=#{config.class.name}",
    #                                        "" ] if catalog_controller_debug_verbose

    config.view.gallery.partials = %i[index_header index]
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]

    # set maximum results per page to support bootstrap page sorting
    # in dashboard.
    # config.max_per_page = 1000000

    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)
    config.search_builder_class = Hyrax::CatalogSearchBuilder

    # Show gallery view
    config.view.gallery.partials = %i[index_header index]
    config.view.slideshow.partials = [:index]

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
        qt: "search",
        rows: 10,
        # qf: "title_tesim description_tesim creator_tesim keyword_tesim"
        qf: "title_tesim name_tesim creator_tesim description_tesim grantnumber_tesim methodology_tesim subject_tesim keyword_tesim referenced_by_tesim all_text_timv"
    }

    # solr field configuration for document/show views
    config.index.title_field = solr_name("title", :stored_searchable)
    config.index.display_type_field = solr_name("has_model", :symbol)
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # # solr fields that will be treated as facets by the blacklight application
    # #   The ordering of the field names is the order of the display
    # #config.add_facet_field solr_name("human_readable_type", :facetable), label: "Type", limit: 5
    # config.add_facet_field solr_name("resource_type", :facetable), label: "Resource Type", limit: 5
    # config.add_facet_field solr_name("creator", :facetable), limit: 5
    # #config.add_facet_field solr_name("contributor", :facetable), label: "Contributor", limit: 5
    # #config.add_facet_field solr_name("keyword", :facetable), limit: 5
    # #config.add_facet_field solr_name("subject", :facetable), limit: 5
    # config.add_facet_field solr_name("subject_discipline", :facetable), label: "Discipline", limit: 5
    # config.add_facet_field solr_name("language", :facetable), limit: 5
    # #config.add_facet_field solr_name("based_near_label", :facetable), limit: 5
    # #config.add_facet_field solr_name("publisher", :facetable), limit: 5
    # #config.add_facet_field solr_name("file_format", :facetable), limit: 5
    # #config.add_facet_field solr_name('member_of_collections', :symbol), limit: 5, label: 'Collections'

    configure_facet_fields( config )

    # The generic_type isn't displayed on the facet list
    # It's used to give a label to the filter that comes from the user profile
    config.add_facet_field solr_name("generic_type", :facetable), if: false

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name("title", :stored_searchable), label: "Title", itemprop: 'name', if: false
    config.add_index_field solr_name("creator", :stored_searchable), itemprop: 'creator', link_to_search: solr_name("creator", :facetable)
    config.add_index_field solr_name("description", :stored_searchable), itemprop: 'description', helper_method: :iconify_auto_link
    config.add_index_field solr_name("keyword", :stored_searchable), itemprop: 'keywords', link_to_search: solr_name("keyword", :facetable)
    config.add_index_field solr_name("referenced_by", :stored_searchable), itemprop: 'referenced_by', label: "Citation to related publication", helper_method: :iconify_auto_link
    config.add_index_field solr_name("subject_discipline", :stored_searchable), itemprop: 'subject_discipline', label: "Discipline", link_to_search: solr_name("subject_discipline", :facetable)

    # This was the default that came with hyrax.
    #config.add_index_field solr_name("title", :stored_searchable), label: "Title", itemprop: 'name', if: false
    #config.add_index_field solr_name("description", :stored_searchable), itemprop: 'description', helper_method: :iconify_auto_link
    #config.add_index_field solr_name("keyword", :stored_searchable), itemprop: 'keywords', link_to_search: solr_name("keyword", :facetable)
    #config.add_index_field solr_name("subject", :stored_searchable), itemprop: 'about', link_to_search: solr_name("subject", :facetable)
    #config.add_index_field solr_name("subject_discipline", :stored_searchable), label: "Discipline", link_to_search: solr_name("subject_discipline", :facetable)
    #config.add_index_field solr_name("creator", :stored_searchable), itemprop: 'creator', link_to_search: solr_name("creator", :facetable)
    #config.add_index_field solr_name("contributor", :stored_searchable), itemprop: 'contributor', link_to_search: solr_name("contributor", :facetable)
    #config.add_index_field solr_name("proxy_depositor", :symbol), label: "Depositor", helper_method: :link_to_profile
    #config.add_index_field solr_name("depositor"), label: "Owner", helper_method: :link_to_profile
    #config.add_index_field solr_name("publisher", :stored_searchable), itemprop: 'publisher', link_to_search: solr_name("publisher", :facetable)
    #config.add_index_field solr_name("based_near_label", :stored_searchable), itemprop: 'contentLocation', link_to_search: solr_name("based_near_label", :facetable)
    #config.add_index_field solr_name("language", :stored_searchable), itemprop: 'inLanguage', link_to_search: solr_name("language", :facetable)
    #config.add_index_field solr_name("date_uploaded", :stored_sortable, type: :date), itemprop: 'datePublished', helper_method: :human_readable_date
    #config.add_index_field solr_name("date_modified", :stored_sortable, type: :date), itemprop: 'dateModified', helper_method: :human_readable_date
    #config.add_index_field solr_name("date_created", :stored_searchable), itemprop: 'dateCreated', helper_method: :human_readable_date
    #config.add_index_field solr_name("rights_license", :stored_searchable), helper_method: :rights_license_links
    #config.add_index_field solr_name("rights_statement", :stored_searchable), helper_method: :rights_statement_links
    #config.add_index_field solr_name("license", :stored_searchable), helper_method: :license_links
    #config.add_index_field "total_file_size_lts", label: "Total File Size", helper_method: :human_readable_file_size
    #config.add_index_field solr_name("resource_type", :stored_searchable), label: "Resource Type", link_to_search: solr_name("resource_type", :facetable)
    #config.add_index_field solr_name("file_format", :stored_searchable), link_to_search: solr_name("file_format", :facetable)
    #config.add_index_field solr_name("identifier", :stored_searchable), helper_method: :index_field_link, field_name: 'identifier'
    #config.add_index_field solr_name("embargo_release_date", :stored_sortable, type: :date), label: "Embargo release date", helper_method: :human_readable_date
    #config.add_index_field solr_name("lease_expiration_date", :stored_sortable, type: :date), label: "Lease expiration date", helper_method: :human_readable_date

    #To be able to sort by title
    config.add_index_field solr_name("title", :stored_sortable, type: :string), label: "Title"

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field solr_name("title", :stored_searchable)
    config.add_show_field solr_name("description", :stored_searchable)
    config.add_show_field solr_name("keyword", :stored_searchable)
    config.add_show_field solr_name("subject", :stored_searchable)
    config.add_show_field solr_name("subject_discipline", :stored_searchable)
    config.add_show_field solr_name("creator", :stored_searchable)
    config.add_show_field solr_name("contributor", :stored_searchable)
    config.add_show_field solr_name("publisher", :stored_searchable)
    config.add_show_field solr_name("based_near_label", :stored_searchable)
    config.add_show_field solr_name("language", :stored_searchable)
    config.add_show_field solr_name("date_created", :stored_searchable)
    config.add_show_field solr_name("date_modified", :stored_searchable)
    config.add_show_field solr_name("date_published", :stored_searchable), label: "Published"
    config.add_show_field "date_published_dtsim"
    config.add_show_field solr_name("date_uploaded", :stored_searchable)
    config.add_show_field solr_name("rights_license", :stored_searchable)
    config.add_show_field solr_name("rights_statement", :stored_searchable)
    config.add_show_field solr_name("license", :stored_searchable)
    config.add_show_field "total_file_size_lts"
    config.add_show_field solr_name("resource_type", :stored_searchable), label: "Resource Type"
    config.add_show_field solr_name("format", :stored_searchable)
    config.add_show_field solr_name("identifier", :stored_searchable)
    config.add_show_field solr_name("referenced_by", :stored_searchable), label: "Citation to related publication"

    config.add_show_field solr_name("date_coverage", :stored_searchable), label: "Date Coverage"

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
      title_name = solr_name("title", :stored_searchable)
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

    config.add_search_field('based_near') do |field|
      field.label = "Location"
      solr_name = solr_name("based_near_label", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('contributor') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = solr_name("contributor", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      solr_name = solr_name("creator", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('date_created') do |field|
      solr_name = solr_name("created", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      solr_name = solr_name("depositor", :symbol)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.label = "Abstract or Summary"
      solr_name = solr_name("description", :stored_searchable)
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

    config.add_search_field('format') do |field|
      solr_name = solr_name("format", :stored_searchable)
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

    config.add_search_field('identifier') do |field|
      solr_name = solr_name("id", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('keyword') do |field|
      solr_name = solr_name("keyword", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      solr_name = solr_name("language", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('license') do |field|
      solr_name = solr_name("license", :stored_searchable)
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

    config.add_search_field('publisher') do |field|
      solr_name = solr_name("publisher", :stored_searchable)
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

    config.add_search_field('resource_type') do |field|
      solr_name = solr_name("resource_type", :stored_searchable)
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

    config.add_search_field('rights_statement') do |field|
      solr_name = solr_name("rights_statement", :stored_searchable)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      solr_name = solr_name("subject", :stored_searchable)
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

    config.add_search_field('title') do |field|
      solr_name = solr_name("title", :stored_searchable)
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
    config.add_sort_field "score desc, #{modified_field} desc", label: "relevance"
    config.add_sort_field "#{uploaded_field} desc", label: "date created \u25BC"
    config.add_sort_field "#{uploaded_field} asc", label: "date created \u25B2"
    config.add_sort_field "#{modified_field} desc", label: "last modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "last modified \u25B2"

    # Need to reindex the collection to be able to use these.
    # config.add_sort_field "titl_ssi desc", label: "date modified \u25BC"
    # config.add_sort_field "title_ssi asc", label: "date modified \u25B2"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
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

  # get search results from the solr index
  def index
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if catalog_controller_debug_verbose
    (@response, @document_list) = search_results(index_params)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@document_list.size=#{@document_list.size}",
                                           "@document_list.map(&:id)=#{@document_list.map(&:id)}",
                                           "" ] if catalog_controller_debug_verbose

    respond_to do |format|
      format.html { store_preferred_view }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json do
        @presenter = ::Deepblue::SearchResultJsonPresenter.new( @response,
                                                                @document_list,
                                                                facets_from_request,
                                                                blacklight_config )
      end
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  def index_params
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params.class.name=#{params.class.name}",
                                           "params=#{params}",
                                           "" ] if catalog_controller_debug_verbose
    respond_to do |format|
      format.html { return params }
      format.rss  { return params }
      format.atom { return params }
      format.json { return index_params_json }
    end
  end

  def index_params_json
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params.class.name=#{params.class.name}",
                                           "params=#{params}",
                                           "@@facet_solr_name_to_name=#{@@facet_solr_name_to_name}",
                                           "" ] if catalog_controller_debug_verbose
    f = params["f"]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "f=#{f}",
                                           "" ] if catalog_controller_debug_verbose
    p2 = params.deep_dup
    if f.present? && catalog_controller_allow_search_fix_for_json
      need_fix = false
      f.each_pair do |k,_v|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "k=#{k}",
                                               "CatalogController.facet_solr_name_to_name(k)=#{CatalogController.facet_solr_name_to_name(k)}",
                                               "" ] if catalog_controller_debug_verbose
        need_fix = true if CatalogController.facet_solr_name_to_name(k).blank?
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "need_fix=#{need_fix}",
                                             "" ] if catalog_controller_debug_verbose
      if need_fix
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "fixing...",
                                               "" ] if catalog_controller_debug_verbose
        old_params = params
        params = old_params.to_unsafe_hash
        new_f = {}
        f.each_pair do |k,v|
          fix_name = CatalogController.facet_solr_name_to_name(k)
          if fix_name.present?
            new_f[k] = v
          else
            new_f[CatalogController.solr_name(k, :facetable)] = v
          end
        end
        params["f"] = new_f
      else
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "skipped fixing",
                                               "" ] if catalog_controller_debug_verbose
      end
    end
    # no idea how params becomes nil here, but....
    params = p2 if params.nil?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "p2=#{p2}",
                                           "search_builder_class.name=#{search_builder_class.name}",
                                           "" ] if catalog_controller_debug_verbose
    return params
  end


end
