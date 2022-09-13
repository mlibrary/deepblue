# frozen_string_literal: true

module Deepblue

  class DoiMintingService

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :doi_minting_service_debug_verbose,          default: false
    mattr_accessor :doi_ensure_doi_minted_debug_verbose,        default: false
    mattr_accessor :doi_minting_2021_service_debug_verbose,     default: false

    mattr_accessor :doi_behavior_debug_verbose,                 default: false
    mattr_accessor :doi_controller_behavior_debug_verbose,      default: false
    mattr_accessor :doi_minting_job_debug_verbose,              default: false
    mattr_accessor :register_doi_job_debug_verbose,             default: false
    mattr_accessor :bolognese_hyrax_work_readers_debug_verbose, default: false
    mattr_accessor :bolognese_hyrax_work_writers_debug_verbose, default: false
    mattr_accessor :data_cite_registrar_debug_verbose,          default: false
    mattr_accessor :hyrax_identifier_dispatcher_debug_verbose,  default: false

    mattr_accessor :doi_mint_on_publication_event,                  default: false
    mattr_accessor :doi_minting_service_integration_enabled,        default: false
    mattr_accessor :doi_minting_service_integration_hostnames,      default: [ 'deepblue.local',
                                                                              'testing.deepblue.lib.umich.edu',
                                                                              'staging.deepblue.lib.umich.edu',
                                                                              'deepblue.lib.umich.edu' ].freeze
    mattr_accessor :doi_minting_service_integration_hostnames_prod, default: [ 'deepblue.lib.umich.edu',
                                                                              'testing.deepblue.lib.umich.edu' ].freeze
    mattr_accessor :doi_publisher_name,                             default: 'University of Michigan'.freeze
    mattr_accessor :doi_resource_type,                              default: 'Dataset'.freeze
    mattr_accessor :doi_resource_types,                             default: [ 'Dataset', 'Fileset' ].freeze


    mattr_accessor :doi_minting_2021_service_enabled,               default: true
    mattr_accessor :doi_minting_2021_service_direct,                default: true
    mattr_accessor :doi_minting_service_email_user_on_success,      default: false

    mattr_accessor :test_base_url,           default: "https://api.test.datacite.org/"
    mattr_accessor :test_mds_base_url,       default: "https://mds.test.datacite.org/"
    mattr_accessor :production_base_url,     default: "https://api.datacite.org/"
    mattr_accessor :production_mds_base_url, default: "https://mds.datacite.org/"

    def self.datacite_registrar( debug_verbose: false, task: false )
      datacite = ::Deepblue::DataCiteRegistrar.new
      datacite.debug_verbose = true if debug_verbose
      datacite.debug_verbose_puts = true if task && debug_verbose
      return datacite
    end

    def self.ensure_doi_minted( id: nil,
                                curation_concern: nil,
                                msg_handler:,
                                debug_verbose: doi_minting_service_debug_verbose || doi_ensure_doi_minted_debug_verbose )

      debug_verbose = debug_verbose || doi_minting_service_debug_verbose || doi_ensure_doi_minted_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "curation_concern.nil?=#{curation_concern.nil?}",
                                             "msg_handler=#{msg_handler}",
                                             "" ] if debug_verbose
      id ||= curation_concern&.id
      w = curation_concern
      w ||= ::PersistHelper.find id
      msg_handler.msg_verbose "id=#{id}"
      msg_handler.msg_verbose "work found=#{w.present?}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "work found=#{w.present?}",
                                             "" ] if debug_verbose
      if w.present?
        msg_handler.msg "Ensure DOI minted for work #{id} ..."
      else
        msg_handler.msg "#{id} work not found. Can't mint DOI."
        return false
      end
      datacite = datacite_registrar( debug_verbose: debug_verbose, task: msg_handler.to_console )
      url = datacite.work_url(w)
      doi = w.doi
      doi_minted = w.doi_minted?
      msg_handler.msg_verbose "work url=#{url}"
      msg_handler.msg_verbose "doi #{doi}"
      msg_handler.msg_verbose "work doi_minted?=#{doi_minted}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_url=#{url}",
                                             "doi=#{doi}",
                                             "work doi_minted?=#{doi_minted}",
                                             "" ] if debug_verbose
      unless doi_minted
        msg_handler.msg "Calling registrar mint doi."
        registrar_mint_doi( curation_concern: w,
                            current_user: nil,
                            msg_handler: msg_handler,
                            debug_verbose: debug_verbose,
                            datacite: datacite,
                            registrar: nil,
                            registrar_opts: {} )
        findable = datacite_registrar.doi_findable? w
        msg_handler.msg "Work #{url} is findable? #{findable}"
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "work doi findable=#{findable}",
                                               "" ] if debug_verbose
        return findable
      end

      findable = datacite.doi_findable? w
      msg_handler.msg_verbose "work doi findable? #{findable}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work doi findable?=#{findable}",
                                             "" ] if debug_verbose
      return true if findable

      msg_handler.msg_verbose datacite.client.get_metadata(w.doi) if debug_verbose
      # raw = datacite.client.get_metadata_raw(w.doi)
      # xraw = Nokogiri::XML(raw)

      client = datacite.client
      # w.doi_is_registered?
      #
      # client.get_url(w.doi)
      # ==> error
      #
      doi = doi.sub( /^doi:/, '' )
      client.register_url(doi, url)
      findable = datacite.doi_findable? w
      msg_handler.msg "Work #{url} is findable? #{findable}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work doi findable=#{findable}",
                                             "" ] if debug_verbose
      return findable
    end

    # <b>DEPRECATED:</b> Please use <tt>registrar_mint_doi</tt> instead.
    def self.mint_doi_for( curation_concern:,
                           current_user:,
                           target_url:,
                           debug_verbose: ::Deepblue::DoiMintingService.doi_minting_service_debug_verbose )

      debug_verbose ||= ::Deepblue::DoiMintingService.doi_minting_service_debug_verbose
      warn "[DEPRECATION] `mint_doi_for` is deprecated.  Please use `registrar_mint_doi` instead."
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "current_user=#{current_user}",
                                             "target_url=#{target_url}",
                                             "" ] if debug_verbose
      service = ::Deepblue::DoiMintingService.new( curation_concern: curation_concern,
                                                 current_user: current_user,
                                                 target_url: target_url )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "about to call service.run",
                                             "" ] if debug_verbose
      service.run
    rescue Exception => e # rubocop:disable Lint/RescueException
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "current_user=#{current_user}",
                                             "target_url=#{target_url}",
                                             "rescue exception -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}",
                                             "" ] if debug_verbose
      Rails.logger.debug "DoiMintingService.mint_doi_for( curation_concern id = #{curation_concern.id},"\
                         " current_user = #{current_user}, target_url = #{target_url} )"\
                         " rescue exception -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      unless curation_concern.nil?
        curation_concern.reload # consider locking curation_concern
        curation_concern.doi = nil
        curation_concern.save
        curation_concern.reload
        curation_concern.doi
      end
      raise
    end

    def self.doi_mint_job( curation_concern:,
                           current_user: nil,
                           event_note: 'DoiMintingService',
                           job_delay: 0,
                           msg_handler: nil,
                           debug_verbose: ::Deepblue::DoiMintingService.doi_minting_service_debug_verbose )

      debug_verbose ||= ::Deepblue::DoiMintingService.doi_minting_service_debug_verbose
      id = curation_concern.id
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "class.name=#{curation_concern.class.name}",
                                             "curation_concern.doi=#{curation_concern.doi}",
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "job_delay=#{job_delay}",
                                             "" ] if doi_minting_service_debug_verbose
      current_user = current_user.email if current_user.respond_to? :email
      target_url = EmailHelper.curation_concern_url( curation_concern: curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{id}",
                                             "class.name=#{curation_concern.class.name}",
                                             "target_url=#{target_url}",
                                             "curation_concern.doi=#{curation_concern.doi}",
                                             "about to call doi minting job",
                                             "" ] if debug_verbose
      raise IllegalOperation, "Attempting to mint doi before id is created." if target_url.blank?
      if DoiMintingService.doi_minting_2021_service_enabled
        ::RegisterDoiJob.perform_later( curation_concern,
                                        current_user: current_user,
                                        debug_verbose: debug_verbose,
                                        registrar: curation_concern.doi_registrar.presence,
                                        registrar_opts: curation_concern.doi_registrar_opts )
      else
        ::DoiMintingJob.perform_later( curation_concern.id,
                                       current_user: current_user,
                                       job_delay: job_delay,
                                       target_url: target_url,
                                       debug_verbose: debug_verbose )
      end
      return true
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "DoiBehavior.doi_mint for curation_concern.id #{id} -- #{e.class}: #{e.message} at #{e.backtrace[0]}"
    end

    def self.doi_pending_finder( data_set_ids_found:,
                                 file_set_ids_found:,
                                 msg_handler:,
                                 debug_verbose: ::Deepblue::DoiMintingService.doi_minting_service_debug_verbose )

      debug_verbose ||= ::Deepblue::DoiMintingService.doi_minting_service_debug_verbose
      msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                               ::Deepblue::LoggingHelper.called_from,
                               "data_set_ids_found.is_a? Array=#{data_set_ids_found.is_a? Array}",
                               "file_set_ids_found.is_a? Array=#{file_set_ids_found.is_a? Array}",
                               "msg_queue=#{msg_queue}",
                               "" ] if debug_verbose

      if data_set_ids_found.is_a? Array
        DataSet.all.each do |work|
          data_set_ids_found << work.id if work.doi_pending?
        end
      end

      if file_set_ids_found.is_a? Array
        FileSet.all.each do |fs|
          file_set_ids_found << fs.id if fs.doi_pending?
        end
      end

    end

    def self.registrar_mint_doi( curation_concern:,
                                 current_user: nil,
                                 msg_handler: nil,
                                 debug_verbose: ::Deepblue::DoiMintingService.doi_minting_service_debug_verbose,
                                 datacite: nil,
                                 registrar: nil,
                                 registrar_opts: {})

      debug_verbose ||= ::Deepblue::DoiMintingService.doi_minting_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi_minting_2021_service_direct=#{doi_minting_2021_service_direct}",
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "curation_concern&.id=#{curation_concern&.id}",
                                             "curation_concern&.doi=#{curation_concern&.doi}",
                                             "current_user=#{current_user}",
                                             "registrar=#{registrar}",
                                             "registrar_opts=#{registrar_opts}",
                                             "" ] if debug_verbose
      msg_handler ||= ::Deepblue::MessageHandler.new( to_console: false, debug_verbose: debug_verbose )
      current_user = curation_concern.depositor if current_user.blank?
      user = User.find_by_user_key( current_user )
      if doi_minting_2021_service_direct
        if datacite.blank?
          datacite = ::Deepblue::DataCiteRegistrar.new
          datacite.debug_verbose = debug_verbose
        end
        datacite.mint_doi( work: curation_concern )
      else
        registrar ||= ::Deepblue::DataCiteRegistrar
        Hyrax::Identifier::Dispatcher.for(registrar.to_sym,
                                          **registrar_opts).assign_for_single_value!(object: curation_concern,
                                                                                     attribute: :doi) do
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "RegisterDoiJob model (curation_concern.id #{curation_concern.id}) updated.",
                                                 "curation_concern.class.name=#{curation_concern.class.name}",
                                                 "curation_concern.id=#{curation_concern.id}",
                                                 "curation_concern.doi=#{curation_concern.doi}",
                                                 "" ] if debug_verbose
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "RegisterDoiJob model (curation_concern.id #{curation_concern.id}) updated.",
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "curation_concern.id=#{curation_concern.id}",
                                             "curation_concern.doi=#{curation_concern.doi}",
                                             "" ] if debug_verbose
      curation_concern.provenance_mint_doi( current_user: current_user, event_note: 'DoiMintingService' )
      if curation_concern.respond_to?( :email_event_mint_doi_user ) && ::Deepblue::DoiMintingService.doi_minting_service_email_user_on_success
        curation_concern.email_event_mint_doi_user( current_user: current_user, event_note: 'DoiMintingService' )
      end
      # do success callback
      if Hyrax.config.callback.set?( :after_doi_success )
        Hyrax.config.callback.run( :after_doi_success, curation_concern, user, timestamp_end )
      end
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "RegisterDoiJob.perform(#{curation_concern&.id}, #{e.class}: #{e.message} at #{e.backtrace[0]}"
      raise
    end

    attr :current_user, :curation_concern, :metadata, :target_url, :debug_verbose

    def initialize( curation_concern:,
                    current_user:,
                    target_url:,
                    msg_handler: nil,
                    debug_verbose: ::Deepblue::DoiMintingService.doi_minting_service_debug_verbose )

      debug_verbose ||= ::Deepblue::DoiMintingService.doi_minting_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if debug_verbose
      @curation_concern = curation_concern
      @current_user = current_user
      @target_url = target_url
      @metadata = generate_metadata
      @debug_verbose = debug_verbose
    end

    def run
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if debug_verbose
      rv = doi_server_reachable?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "doi_server_reachable? rv=#{rv}",
                                             "" ] if debug_verbose
      return mint_doi_failed unless rv
      curation_concern.reload # consider locking curation_concern
      curation_concern.doi = mint_doi
      curation_concern.save
      curation_concern.reload
      curation_concern.provenance_mint_doi( current_user: current_user, event_note: 'DoiMintingService' )
      if curation_concern.respond_to?( :email_event_mint_doi_user ) && ::Deepblue::DoiMintingService.doi_minting_service_email_user_on_success
        curation_concern.email_event_mint_doi_user( current_user: current_user, event_note: 'DoiMintingService', message: message )
      end
      curation_concern.doi
    end

    def self.print_ezid_config
      config = Ezid::Client.config
      puts "Ezid::Client.config.host = #{config.host}"
      puts "Ezid::Client.config.port = #{config.port}"
      puts "Ezid::Client.config.user = #{config.user}"
      puts "Ezid::Client.config.password = #{config.password}"
      puts "Ezid::Client.config.default_shoulder = #{config.default_shoulder}"
    end

    def ezid_config
      config = Ezid::Client.config
      return [ "Ezid::Client.config.host = #{config.host}",
               "Ezid::Client.config.port = #{config.port}",
               "Ezid::Client.config.user = #{config.user}",
               # "Ezid::Client.config.password = #{config.password}",
               "Ezid::Client.config.default_shoulder = #{config.default_shoulder}" ]
    end

    # private # lets not bother with private stuff until this is actually working

      # Any error raised during connection is considered false
      def doi_server_reachable?
        Ezid::Client.new.server_status.up? rescue false
      end

      def generate_metadata
        Ezid::Metadata.new.tap do |md|
          md.datacite_title = curation_concern.title.first
          md.datacite_publisher = DoiMintingService.doi_publisher_name
          md.datacite_publicationyear = Date.today.year.to_s
          md.datacite_resourcetype = DoiMintingService.doi_resource_type
          md.datacite_creator = if curation_concern.work?
                                  curation_concern.creator.join(';')
                                else
                                  curation_concern.parent.creator.join(';')
                                end
          # md.target = Rails.application.routes.url_helpers.hyrax_data_set_url(id: curation_concern.id)
          md.target = target_url
        end
      end

      def mint_doi
        # identifier = Ezid::Identifier.create(@metadata)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.id=#{curation_concern.id}",
                                               "metadata=#{metadata}",
                                               "" ] if debug_verbose

        # Rails.logger.debug "DoiMintingService.mint_doi( #{metadata} )"
        # msg = ezid_config.join("\n")
        # Rails.logger.debug msg
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.id=#{curation_concern.id}",
                                               "", ] + ezid_config if debug_verbose
        shoulder = Ezid::Client.config.default_shoulder
        identifier = Ezid::Identifier.mint( shoulder, @metadata )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.id=#{curation_concern.id}",
                                               "metadata=#{metadata}",
                                               "identifier=#{identifier}",
                                               "identifier.id=#{identifier.id}",
                                               "" ] if debug_verbose
        identifier.id
      end

      def mint_doi_failed
        Rails.logger.error "DoiMintingService.mint_doi_failed curation_concern id = #{curation_concern.id}"
        curation_concern.reload # consider locking curation_concern
        curation_concern.doi = nil
        curation_concern.save
        curation_concern.reload
        curation_concern.doi
      end

  end

end
