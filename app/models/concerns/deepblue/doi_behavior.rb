# frozen_string_literal: true

module Deepblue

  class DoiError < RuntimeError
  end

  module DoiBehavior

    mattr_accessor :doi_behavior_debug_verbose, default: ::Deepblue::DoiMintingService.doi_behavior_debug_verbose

    mattr_accessor :doi_minting_enabled,       default: true
    #mattr_accessor :doi_pending,               default: 'doi_pending'.freeze
    mattr_accessor :doi_minimum_file_count,    default: 1
    mattr_accessor :doi_pending_timeout_delta, default: ::Deepblue::DoiMintingService.doi_pending_timeout_delta

    mattr_accessor :doi_regex, default: /\A10\.\d{4,}(\.\d+)*\/[-._;():\/A-Za-z\d]+\z/.freeze

    def self.doi_is_registered?( doi: )
      # doi_status_when_public.in?(['registered', 'findable'])
      return false unless DoiBehavior.doi_minted?( doi: doi )
      return false if DoiBehavior.doi_pending?( doi: doi )
      return true
    end

    def self.doi_minted?( doi: )
      return false if doi.nil?
      return false if DoiBehavior.doi_pending?( doi: doi )
      # return false if doi.blank? # use this instead?
      return true
      # !doi.nil?
    rescue
      nil
    end

    def self.doi_needs_minting?( doi: )
      return true if doi.blank?
      return true if ::Deepblue::DoiMintingService::DOI_MINT_NOW == doi
      if DoiBehavior.doi_pending?( doi: doi )
        return true if DoiBehavior.doi_pending_timeout?( doi: doi )
      end
      return false
    end

    def self.doi_pending?( doi: )
      return false if doi.blank?
      return true if doi =~ /pending/
      return false
    end

    def self.doi_pending_init( as_of: DateTime.now )
      rv = "DOI pending as of #{as_of}"
      return rv
    end

    def self.doi_pending_timeout?( doi: )
      # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
      #                                       ::Deepblue::LoggingHelper.called_from,
      #                                       "doi=#{doi}",
      #                                       "false unless DoiBehavior.doi_pending?( doi: doi )=#{DoiBehavior.doi_pending?( doi: doi )}",
      #                                       "" ]
      return false unless DoiBehavior.doi_pending?( doi: doi )
      match = doi.match( /^.*pending as of (\d.+)$/ )
      return true if match.blank?
      as_of = match[1]
      return false if as_of.blank?
      begin
        as_of = DateTime.parse( as_of )
        as_of = as_of + DoiBehavior.doi_pending_timeout_delta
        # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
        #                                       ::Deepblue::LoggingHelper.called_from,
        #                                       "doi=#{doi}",
        #                                       "as_of=#{as_of}",
        #                                       "true if as_of < DateTime.now=#{as_of < DateTime.now}",
        #                                       "" ]
        return true if as_of < DateTime.now
      rescue Exception => e
        # puts e
        return false
      end
      return false
    end

    def self.doi_render( value )
      value = value.first if value.is_a? Array
      return value if DoiBehavior.doi_pending?( doi: value )
      return value if value.start_with? 'http'
      return value.sub 'doi:', 'https://doi.org/'
    end

    def doi_findable?
      # doi_status_when_public == 'findable'
      doi_is_registered? # best equivelant
    end

    def doi_has_status?
      # doi_status_when_public.in?(::Deepblue::DataCiteRegistrar::STATES)
      doi_minted?
    end

    def doi_is_registered?
      DoiBehavior.doi_is_registered?( doi: doi )
    end

    def doi_minted?
      DoiBehavior.doi_minted?( doi: doi )
    end

    def doi_minting_enabled?
      ::Deepblue::DoiBehavior.doi_minting_enabled
    end

    def doi_needs_minting?
      DoiBehavior.doi_needs_minting?( doi: doi )
    end

    def doi_pending_init
      DoiBehavior.doi_pending_init
    end

    def doi_pending?
      DoiBehavior.doi_pending?( doi: doi )
    end

    def doi_pending_timeout?
      DoiBehavior.doi_pending_timeout?( doi: doi )
    end

    def doi_registrar
      'datacite'
    end

    def doi_registrar_opts
      {}
    end

    def doi_mint( current_user: nil,
                  event_note: '',
                  enforce_minimum_file_count: true,
                  job_delay: 0,
                  returnMessages: [],
                  debug_verbose: doi_behavior_debug_verbose )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{id}",
                                             "class.name=#{self.class.name}",
                                             "doi=#{doi}",
                                             "doi_needs_minting?=#{doi_needs_minting?}",
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "enforce_minimum_file_count=#{enforce_minimum_file_count}",
                                             "job_delay=#{job_delay}",
                                             "Settings.datacite.active=#{Settings.datacite.active}",
                                             "" ] if debug_verbose

      rv = false
      begin # until true for break
        unless Settings.datacite.active
          returnMessages << MsgHelper.t( 'data_set.doi_minting_service_inactive' )
          break
        end
        unless doi_needs_minting?
          returnMessages << MsgHelper.t( 'data_set.doi_is_already_pending' )
          break
        end
        if work? && enforce_minimum_file_count && file_sets.count < doi_minimum_file_count
          returnMessages << MsgHelper.t( 'data_set.doi_requires_work_with_files' )
          break
        end
        self.doi = doi_pending_init
        self.save
        self.reload
        ::Deepblue::DoiMintingService.doi_mint_job( curation_concern: self,
                                                    current_user: current_user,
                                                    event_note: event_note,
                                                    job_delay: job_delay,
                                                    debug_verbose: debug_verbose )
        returnMessages << MsgHelper.t( 'data_set.doi_minting_started' )
        rv = true
      end until true # for break

      return rv
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "DoiBehavior.doi_mint for curation_concern.id #{id} -- #{e.class}: #{e.message} at #{e.backtrace[0]}"
    end

    def ensure_doi_minted( current_user: nil )
      current_user ||= self.current_user if self.respond_to? :current_user
      ::Deepblue::DoiMintingService.ensure_doi_minted( curation_concern: self,
                                                       current_user: current_user,
                                                       msg_handler: ::Deepblue::MessageHandler.new,
                                                       debug_verbose: doi_behavior_debug_verbose )
    end

  end

end
