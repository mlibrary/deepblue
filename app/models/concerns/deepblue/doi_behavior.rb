# frozen_string_literal: true

module Deepblue

  class DoiError < RuntimeError
  end

  module DoiBehavior

    mattr_accessor :doi_behavior_debug_verbose, default: ::Deepblue::DoiMintingService.doi_behavior_debug_verbose

    mattr_accessor :doi_minting_enabled, default: true
    mattr_accessor :doi_pending, default: 'doi_pending'
    mattr_accessor :doi_minimum_file_count, default: 1

    mattr_accessor :doi_regex, default: /\A10\.\d{4,}(\.\d+)*\/[-._;():\/A-Za-z\d]+\z/.freeze

    def doi_findable?
      # doi_status_when_public == 'findable'
      doi_is_registered? # best equivelant
    end

    def doi_has_status?
      # doi_status_when_public.in?(::Deepblue::DataCiteRegistrar::STATES)
      doi_minted?
    end

    def doi_is_registered?
      # doi_status_when_public.in?(['registered', 'findable'])
      return false unless doi_minted?
      return false if doi_pending?
      return true
    end

    def doi_minted?
      !doi.nil?
    rescue
      nil
    end

    def doi_minting_enabled?
      ::Deepblue::DoiBehavior.doi_minting_enabled
    end

    def doi_pending?
      doi == doi_pending
    end

    def doi_registrar
      'datacite'
    end

    def doi_registrar_opts
      {}
    end

    def doi_mint( current_user: nil, event_note: '', enforce_minimum_file_count: true, job_delay: 0 )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{id}",
                                             "class.name=#{self.class.name}",
                                             "doi=#{doi}",
                                             "current_user=#{current_user}",
                                             "event_note=#{event_note}",
                                             "enforce_minimum_file_count=#{enforce_minimum_file_count}",
                                             "job_delay=#{job_delay}",
                                             "" ] if doi_behavior_debug_verbose
      return false if doi_pending?
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                      ::Deepblue::LoggingHelper.called_from,
      #                                      "curation_concern.id=#{id}",
      #                                      "past doi_pending?" ] if doi_behavior_debug_verbose
      return false if doi_minted?
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                      ::Deepblue::LoggingHelper.called_from,
      #                                      "curation_concern.id=#{id}",
      #                                      "past doi_minted?" ] if doi_behavior_debug_verbose
      return false if work? && enforce_minimum_file_count && file_sets.count < doi_minimum_file_count
      self.doi = doi_pending
      self.save
      self.reload
      ::Deepblue::DoiMintingService.doi_mint_job( curation_concern: self,
                                                  current_user: current_user,
                                                  event_note: event_note,
                                                  job_delay: job_delay )
      # current_user = current_user.email if current_user.respond_to? :email
      # target_url = EmailHelper.curation_concern_url( curation_concern: self )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "curation_concern.id=#{id}",
      #                                        "class.name=#{self.class.name}",
      #                                        "target_url=#{target_url}",
      #                                        "doi=#{doi}",
      #                                        "about to call DoiMintingJob",
      #                                        "" ] if doi_behavior_debug_verbose
      # raise IllegalOperation, "Attempting to mint doi before id is created." if target_url.blank?
      # ::DoiMintingJob.perform_later( id, current_user: current_user, job_delay: job_delay, target_url: target_url )
      return true
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "DoiBehavior.doi_mint for curation_concern.id #{id} -- #{e.class}: #{e.message} at #{e.backtrace[0]}"
    end

    def ensure_doi_minted
      ::Deepblue::DoiMintingService.ensure_doi_minted( curation_concern: self,
                                                       task: false,
                                                       debug_verbose: doi_behavior_debug_verbose )
    end

  end

end
