# frozen_string_literal: true

class DoiMintingJob < ::Hyrax::ApplicationJob

  mattr_accessor :doi_minting_job_debug_verbose, default: false

  queue_as :doi_minting

  def perform( id, current_user: nil, job_delay: 0, target_url: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "curation_concern.id=#{id}",
                                         "current_user=#{current_user}",
                                         "job_delay=#{job_delay}",
                                         "target_url=#{target_url}",
                                         "" ] if doi_minting_job_debug_verbose
    if 0 < job_delay
      return unless ::PersistHelper.find( id ).doi_pending?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "curation_concern.id=#{id}",
                                           "current_user=#{current_user}",
                                           "target_url=#{target_url}",
                                           "sleeping #{job_delay} seconds",
                                           "" ] if doi_minting_job_debug_verbose
      sleep job_delay
    end
    curation_concern = ::PersistHelper.find( id )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "curation_concern.id=#{id}",
                                         ::Deepblue::LoggingHelper.obj_class( "curation_concern", curation_concern ),
                                         "curation_concern.doi=#{curation_concern.doi}",
                                         "curation_concern.doi_pending?=#{curation_concern.doi_pending?}",
                                         "" ] if doi_minting_job_debug_verbose
    return unless curation_concern.doi_pending?
    current_user = curation_concern.depositor if current_user.blank?
    user = User.find_by_user_key( current_user )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "curation_concern.id=#{id}",
                                         "user.email=#{user.email}",
                                         "target_url=#{target_url}",
                                         "Starting..." ] if doi_minting_job_debug_verbose
    # Rails.logger.debug "DoiMintingJob curation_concern id #{id} #{user.email} starting..." if doi_minting_job_debug_verbose
    if ::Deepblue::DoiMintingService.mint_doi_for( curation_concern: curation_concern,
                                                 current_user: current_user,
                                                 target_url: target_url )
      Rails.logger.debug "DoiMintingJob curation_concern id #{id} #{user.email} succeeded." if doi_minting_job_debug_verbose
      # do success callback
      if Hyrax.config.callback.set?( :after_doi_success )
        Hyrax.config.callback.run( :after_doi_success, curation_concern, user, log.created_at )
      end
    else
      Rails.logger.debug "DoiMintingJob curation_concern id #{id} #{user.email} failed." if doi_minting_job_debug_verbose
      # do failure callback
      if Hyrax.config.callback.set?( :after_doi_failure )
        Hyrax.config.callback.run( :after_doi_failure, curation_concern, user, log.created_at )
      end
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "DoiMintingJob.perform(#{id},#{job_delay}) #{e.class}: #{e.message} at #{e.backtrace[0]}" if doi_minting_job_debug_verbose
    raise
  end

end
