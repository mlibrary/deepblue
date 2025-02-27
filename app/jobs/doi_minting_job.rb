# frozen_string_literal: true

class DoiMintingJob < ::Deepblue::DeepblueJob

  queue_as :doi_minting

  # job_delay in seconds
  # def perform( id:,
  #              current_user: nil,
  #              job_delay: 0,
  #              target_url:,
  #              debug_verbose: ::Deepblue::DoiMintingService.doi_minting_job_debug_verbose )
  # hyrax4 / ruby3 upgrade
  def perform( *args )
    args = [{}] if args.nil? || args[0].nil?
    id = args[0][:id]
    current_user = args[0][:current_user]
    job_delay = args[0][:job_delay]
    job_delay ||= 0
    target_url = args[0][:target_url]
    debug_verbose = args[0][:debug_verbose]
    debug_verbose ||= ::Deepblue::DoiMintingService.doi_minting_job_debug_verbose

    debug_verbose = debug_verbose || ::Deepblue::DoiMintingService.doi_minting_job_debug_verbose
    warn "[DEPRECATION] `DoiMintingJob` is deprecated.  Please use `RegisterDoiJob` instead."
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "curation_concern.id=#{id}",
                                         "current_user=#{current_user}",
                                         "job_delay=#{job_delay}",
                                         "target_url=#{target_url}",
                                         "" ] if debug_verbose
    initialize_no_args_hash( id: id, debug_verbose: debug_verbose )
    curation_concern = ::PersistHelper.find( id )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "curation_concern.id=#{id}",
                                           ::Deepblue::LoggingHelper.obj_class( "curation_concern", curation_concern ),
                                           "curation_concern.doi=#{curation_concern.doi}",
                                           "curation_concern.doi_needs_minting?=#{curation_concern.doi_needs_minting?}",
                                           "" ] if debug_verbose
    return unless curation_concern.doi_needs_minting?
    if 0 < job_delay
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "curation_concern.id=#{id}",
                                           "current_user=#{current_user}",
                                           "target_url=#{target_url}",
                                           "sleeping #{job_delay} seconds",
                                           "" ] if debug_verbose
      sleep job_delay
    end
    current_user = curation_concern.depositor if current_user.blank?
    user = User.find_by_user_key( current_user )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         ::Deepblue::LoggingHelper.called_from,
                                         "curation_concern.id=#{id}",
                                         "user.email=#{user.email}",
                                         "target_url=#{target_url}",
                                         "Starting..." ] if debug_verbose
    # Rails.logger.debug "DoiMintingJob curation_concern id #{id} #{user.email} starting..." if debug_verbose
    if ::Deepblue::DoiMintingService.mint_doi_for( curation_concern: curation_concern,
                                                 current_user: current_user,
                                                 target_url: target_url,
                                                 debug_verbose: debug_verbose )
      job_finished
      Rails.logger.debug "DoiMintingJob curation_concern id #{id} #{user.email} succeeded." if debug_verbose
      # do success callback
      if Hyrax.config.callback.set?( :after_doi_success )
        Hyrax.config.callback.run( :after_doi_success, curation_concern, user, timestamp_end )
      end
    else
      Rails.logger.debug "DoiMintingJob curation_concern id #{id} #{user.email} failed." if debug_verbose
      # do failure callback
      if Hyrax.config.callback.set?( :after_doi_failure )
        Hyrax.config.callback.run( :after_doi_failure, curation_concern, user, timestamp_begin )
      end
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    # Rails.logger.error "DoiMintingJob.perform(#{id},#{job_delay}) #{e.class}: #{e.message} at #{e.backtrace[0]}"
    job_status_register( exception: e,
                         rails_log: true,
                         args: { id: id,
                                 current_user: current_user,
                                 job_delay: job_delay,
                                 target_url: target_url,
                                 debug_verbose: debug_verbose } )
    email_failure( task_name: task_name, exception: e, event: event_name )
    raise e
  end

end
