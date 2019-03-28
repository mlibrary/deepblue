# frozen_string_literal: true

class DoiMintingJob < ::Hyrax::ApplicationJob

  queue_as :doi_minting

  def perform( id, current_user: nil, job_delay: 0 )
    Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                         Deepblue::LoggingHelper.called_from,
                                         "work.id=#{id}",
                                         "current_user=#{current_user}",
                                         "job_delay=#{job_delay}"]
    if 0 < job_delay
      return unless ActiveFedora::Base.find( id ).doi_pending?
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "work.id=#{id}",
                                           "current_user=#{current_user}",
                                           "sleeping #{job_delay} seconds"]
      sleep job_delay
    end
    work = ActiveFedora::Base.find( id )
    Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                         Deepblue::LoggingHelper.called_from,
                                         "work.id=#{id}",
                                         Deepblue::LoggingHelper.obj_class( "work", work ),
                                         "work.doi=#{work.doi}",
                                         "work.doi_pending?=#{work.doi_pending?}"]
    return unless work.doi_pending?
    current_user = work.depositor if current_user.blank?
    user = User.find_by_user_key( current_user )
    Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                         Deepblue::LoggingHelper.called_from,
                                         "work.id=#{id}",
                                         "user.email=#{user.email}",
                                         "Starting..." ]
    # Rails.logger.debug "DoiMintingJob work id #{id} #{user.email} starting..."
    if Deepblue::DoiMintingService.mint_doi_for( work: work, current_user: current_user )
      Rails.logger.debug "DoiMintingJob work id #{id} #{user.email} succeeded."
      # do success callback
      if Hyrax.config.callback.set?( :after_doi_success )
        Hyrax.config.callback.run( :after_doi_success, work, user, log.created_at )
      end
    else
      Rails.logger.debug "DoiMintingJob work id #{id} #{user.email} failed."
      # do failure callback
      if Hyrax.config.callback.set?( :after_doi_failure )
        Hyrax.config.callback.run( :after_doi_failure, work, user, log.created_at )
      end
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "DoiMintingJob.perform(#{id},#{job_delay}) #{e.class}: #{e.message} at #{e.backtrace[0]}"
    raise
  end

end
