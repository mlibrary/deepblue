# frozen_string_literal: true

module Deepblue

  class DoiError < RuntimeError
  end

  module DoiBehavior

    DOI_MINTING_ENABLED = true
    DOI_PENDING = 'doi_pending'
    DOI_MINIMUM_FILE_COUNT = 1

    def doi_minted?
      !doi.nil?
    rescue
      nil
    end

    def doi_minting_enabled?
      ::Deepblue::DoiBehavior::DOI_MINTING_ENABLED
    end

    def doi_pending?
      doi == DOI_PENDING
    end

    def doi_mint( current_user: nil, event_note: '', enforce_minimum_file_count: true, job_delay: 0 )
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "work.id=#{id}",
                                           "doi=#{doi}",
                                           "current_user=#{current_user}",
                                           "event_note=#{event_note}",
                                           "enforce_minimum_file_count=#{enforce_minimum_file_count}",
                                           "job_delay=#{job_delay}" ]
      return false if doi_pending?
      # Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                      Deepblue::LoggingHelper.called_from,
      #                                      "work.id=#{id}",
      #                                      "past doi_pending?" ]
      return false if doi_minted?
      # Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                      Deepblue::LoggingHelper.called_from,
      #                                      "work.id=#{id}",
      #                                      "past doi_minted?" ]
      return false if enforce_minimum_file_count && file_sets.count < DOI_MINIMUM_FILE_COUNT
      self.doi = DOI_PENDING
      self.save
      self.reload
      current_user = current_user.email if current_user.respond_to? :email
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "work.id=#{id}",
                                           "doi=#{doi}",
                                           "about to call DoiMintingJob" ]
      ::DoiMintingJob.perform_later( id, current_user: current_user, job_delay: job_delay )
      return true
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "DoiBehavior.doi_mint for curation_concern.id #{id} -- #{e.class}: #{e.message} at #{e.backtrace[0]}"
    end

  end

end
