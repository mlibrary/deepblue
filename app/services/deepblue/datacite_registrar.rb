# frozen_string_literal: true

require_relative './doi_minting_2021_service'
module Deepblue


  # TODO: shift most of functinality to DataSiteRegistrarBehavior module
  class DataCiteRegistrar < Hyrax::Identifier::Registrar

    mattr_accessor :data_cite_registrar_debug_verbose,
                   default: ::Deepblue::DoiMintingService.data_cite_registrar_debug_verbose

    STATES = %w[draft registered findable].freeze

    class_attribute :prefix, :username, :password, :publisher, :mode

    attr_accessor :debug_verbose, :debug_verbose_puts

    def initialize(builder: Hyrax::Identifier::Builder.new(prefix: self.prefix))
      super
      @debug_verbose = data_cite_registrar_debug_verbose
      @debug_verbose_puts = false
    end

    ##
    # @param object [#id]
    #
    # @return [#identifier]
    def register!(object:)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "object=#{object}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      doi = Array(object.try(:doi)).first
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose

      # Return the existing DOI or nil if nothing needs to be done
      should_register = register?(object)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "should_register=#{should_register}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      return Struct.new(:identifier).new(doi) unless should_register
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose

      # Create a draft DOI (if necessary)
      if ::Deepblue::DoiBehavior.doi_needs_minting?( doi: doi )
        doi = mint_draft_doi
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "doi=#{doi}",
                                               "" ], bold_puts: debug_verbose_puts if debug_verbose
      end
      # Submit metadata, register url, and ensure proper status
      submit_to_datacite(curation_concern:object, doi: doi)
      doi = "doi:#{doi}" unless doi.start_with?( "doi:" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      # Return the doi (old or new)
      Struct.new(:identifier).new(doi)
    end

    def mint_doi(curation_concern:)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if debug_verbose
      doi = curation_concern.doi
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ] if debug_verbose

      # Return the existing DOI or nil if nothing needs to be done
      should_register = register?(curation_concern)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "should_register=#{should_register}",
                                             "" ] if debug_verbose
      return unless should_register
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ] if debug_verbose

      # Create a draft DOI (if necessary)
      if ::Deepblue::DoiBehavior.doi_needs_minting?( doi: doi )
        doi = mint_draft_doi
        doi = "doi:#{doi}" unless doi.start_with?( "doi:" )
        curation_concern.doi = doi
        curation_concern.save
        curation_concern.reload
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "doi=#{doi}",
                                               "" ], bold_puts: debug_verbose_puts if debug_verbose
      end
      # Submit metadata, register url, and ensure proper status
      submit_to_datacite(curation_concern: curation_concern, doi: doi, put_metadata: true)
      doi = "doi:#{doi}" unless doi.start_with?( "doi:" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "doi_findable?(curation_concern.id)=#{doi_findable?( curation_concern )}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      curation_concern.doi = doi
      curation_concern.save
      curation_concern.reload
    end

    def mint_draft_doi
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      client.create_draft_doi
    end

    # private # lets not bother with private stuff until this is actually working

    # Should the curation_concern be submitted for registration (or updating)?
    # @return [boolean]
    def register?(curation_concern)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern=#{curation_concern.id}",
                                             "doi_enabled_cc_type?(curation_concern)=#{doi_enabled_cc_type?(curation_concern)}",
                                             "doi_minting_enabled?=#{doi_minting_enabled?}",
                                             # "curation_concern.doi_has_status?=#{curation_concern.doi_has_status?}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      #rv = doi_enabled_cc_type?(curation_concern) && doi_minting_enabled? && curation_concern.doi_has_status?
      return false unless doi_enabled_cc_type?(curation_concern) && doi_minting_enabled?
      doi_findable = doi_findable?( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern=#{curation_concern.id}",
                                             "doi_findable=#{doi_findable}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      rv = !doi_findable
      # TODO: add more checks here to catch cases when updating is unnecessary
      # TODO: check that required metadata is present if set to registered or findable
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      return rv
    end

    # Check if curation_concern is DOI enabled
    def doi_enabled_cc_type?(curation_concern)
      curation_concern.class.ancestors.include?(::Deepblue::DoiBehavior)
      # && curation_concern.class.ancestors.include?(::Deepblue::DataCiteDoiBehavior)
    end

    def doi_active?( curation_concern )
      debug_verbose ||= data_cite_registrar_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "curation_concern.doi=#{curation_concern.doi}",
                                             "" ] if debug_verbose
      return false if curation_concern.blank?
      return false if curation_concern.doi.blank?
      return false if ::Deepblue::DoiBehavior.doi_pending?( doi: curation_concern.doi )
      doi_url = doi_for_register_url( curation_concern.doi )
      json_metadata = client.get_metadata_as_json( doi_url )
      return false if json_metadata.blank?
      json_metadata['data']['attributes']['isActive']
    end

    def doi_findable?(curation_concern)
      debug_verbose ||= data_cite_registrar_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "curation_concern.doi=#{curation_concern.doi}",
                                             "" ] if debug_verbose
      return false if curation_concern.blank?
      return false if curation_concern.doi.blank?
      return false if ::Deepblue::DoiBehavior.doi_pending?( doi: curation_concern.doi )
      url = client.get_url(curation_concern.doi, raise_error: false)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "url=#{url}",
                                             "" ] if debug_verbose
      return !url.blank?
    end

    def doi_minting_enabled?
      # TODO: Check feature flipper (needs to be per curation_concern type? per tenant for Hyku?)
      true
    end

    def public?(curation_concern)
      curation_concern.visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    def client
      @client ||= client_init
    end

    def client_init
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "username=#{self.username}",
                                             #"password=#{self.password}",
                                             "prefix=#{self.prefix}",
                                             "publisher=#{self.publisher}",
                                             "mode=#{mode}",
                                             "debug_verbose=#{debug_verbose}",
                                             "debug_verbose_puts=#{debug_verbose_puts}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      ::Deepblue::DoiMinting2021Service.new(username: self.username,
                                            password: self.password,
                                            prefix: self.prefix,
                                            publisher: self.publisher,
                                            mode: mode,
                                            debug_verbose: debug_verbose,
                                            debug_verbose_puts: debug_verbose_puts)
    end

    # Do the heavy lifting of submitting the metadata, registering the url, and ensuring the correct status
    def submit_to_datacite(curation_concern:, doi: nil, put_metadata: true)
      doi ||= curation_concern.doi
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern=#{curation_concern.id}",
                                             "doi=#{doi}",
                                             "put_metadata=#{put_metadata}",
                                             "1st, put metadata",
                                             "" ] if debug_verbose
      # 1. Add metadata to the DOI (or update it)
      # TODO: check that required metadata is present if current DOI record is registered or findable OR handle error?
      if put_metadata
        datacite_xml = cc_to_datacite_xml(curation_concern)
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "curation_concern=#{curation_concern.id}",
        #                                        "doi=#{doi}",
        #                                        "datacite_xml=#{datacite_xml}",
        #                                        "" ] if debug_verbose
        client.put_metadata(doi, datacite_xml)
      end
      doi_findable = doi_findable?(curation_concern)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern=#{curation_concern.id}",
                                             "doi=#{doi}",
                                             "doi_findable=#{doi_findable}",
                                             "2nd, register the url of the curation_concern if curation_concern.doi_is_registered? #{curation_concern.doi_is_registered?}",
                                             "" ] if debug_verbose
      # 2. Register a url with the DOI if it should be registered or findable
      # NOTE: this doi needs to be sans leading "doi:"
      client.register_url(doi_for_register_url(doi),
                          cc_url(curation_concern)) if curation_concern.doi_is_registered? && !doi_findable

      doi_findable = doi_findable?(curation_concern)

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern=#{curation_concern.id}",
                                             "doi=#{doi}",
                                             "doi_findable=#{doi_findable}",
                                             # "3rd, delete metadata unless curation_concern.doi_findable? && public?(curation_concern) #{curation_concern.doi_findable? && public?(curation_concern)}",
                                             "3rd, delete metadata unless doi_findable?( curation_concern )",
                                             "" ] if debug_verbose
      # 3. Always call delete metadata unless findable and public
      # Do this because it has no real effect on the metadata and
      # the put_metadata or register_url above may have made it findable.
      # client.delete_metadata(doi) unless curation_concern.doi_findable? && public?(curation_concern)
      client.delete_metadata(doi) unless doi_findable
    end

    def doi_for_register_url(doi)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi=#{doi}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      return doi unless doi.to_s.start_with? "doi:"
      rv = doi.sub( 'doi:', '' )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      return rv
    end

    # NOTE: default_url_options[:host] must be set for this method to curation_concern
    def cc_url(curation_concern)
      # if curation_concern.is_a? ::Collection
      #   curation_concern.collection_url
      # else
      #   Rails.application.routes.url_helpers.polymorphic_url(curation_concern)
      # end
      ::Deepblue::EmailHelper.curation_concern_url( curation_concern: curation_concern )
    end

    def cc_to_datacite_xml(curation_concern)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      json = curation_concern.attributes.merge(has_model: curation_concern.has_model.first,
                                               publisher: self.publisher).to_json
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern=#{curation_concern.id}",
                                             "json=#{json}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      rv = Bolognese::Metadata.new( input: json, from: 'hyrax_work' ).datacite
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern=#{curation_concern.id}",
                                             "rv=#{rv}",
                                             "" ], bold_puts: debug_verbose_puts if debug_verbose
      return rv
    end

    def doi_hide_cc( curation_concern: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if debug_verbose
      doi_url = doi_for_register_url( curation_concern.doi )
      # set doi to point to home page
      client.register_url( doi_url, "https://deepblue.lib.umich.edu/data/" ) # TODO: get this url from config
      # hide doi to move from "findable" to "registered"
      client.doi_hide( doi_url )
    end

    def doi_hide_cc_and_register_provenance( curation_concern )
      doi_hide_cc( curation_concern )
      #curation_concern.provenance_mint_doi( current_user: current_user, event_note: 'DoiMintingService' )
      attributes, ignore_blank_key_values = curation_concern.attributes_all_for_provenance, USE_BLANK_KEY_VALUES
      # provenance_log_event( attributes: attributes,
      #                       current_user: current_user,
      #                       event: EVENT_MINT_DOI,
      #                       event_note: event_note,
      #                       ignore_blank_key_values: ignore_blank_key_values )
      # if prov_key_values.blank?
      current_user = nil
      event = 'hide_doi'
      event_note = ''
      prov_key_values = curation_concern.provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                    current_user: current_user,
                                                                    event: event,
                                                                    event_note: event_note,
                                                                    ignore_blank_key_values: ignore_blank_key_values )
      # end
      class_name = curation_concern.class.name
      curation_concern.for_provenance_event_cache_write( event: event, id: id )
      timestamp = LoggingHelper.timestamp_now
      time_zone = LoggingHelper.timestamp_zone
      rv = ProvenanceHelper.log( class_name: class_name,
                                 id: id,
                                 event: event,
                                 event_note: event_note,
                                 timestamp: timestamp,
                                 time_zone: time_zone,
                                 **prov_key_values )
    end

    ## Unused methods for now but may be brought in later when filling in TODOs

    # Fetch the DOI information from DataCite
    # def datacite_record(work)
    #   # TODO: Add some level of caching (could be memoization)
    #   # TODO: Add error handling?
    #   Bolognese::Metadata(input: Array(work.doi).first)
    # end

    # # Check if metadata sent to the registrar has changed
    # def metadata_changed?(work)
    #   fields_to_watch = %w[title creator publisher resource_type identifier description]
    #   diff_work = datacite_record.hyrax_work
    #   diff_work.update_attributes(work.attributes.slice(**fields_to_watch))
    #   diff_work.changes.keys.any? { |k| k.in? fields_to_watch }
    # end

    # # Check if the status in datacite matches the expected status
    # # except when work is not public and doi_status_when_public is findable
    # def status_needs_updating?(work)
    #   current_status = datacite_record.status
    #   expected_status = work.doi_status_when_public
    #
    #   return false if expected_status == :findable && current_status == :registered && !is_public?(work)
    #
    #   current_status != expected_status
    # end
  end

end
