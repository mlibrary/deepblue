# frozen_string_literal: true

class DoiMintingJob < Hyrax::ApplicationJob

  queue_as :doi_minting

  def perform(id)
    work = ActiveFedora::Base.find(id)
    user = User.find_by_user_key(work.depositor)
    Rails.logger.debug "DoiMintingJob work id #{id} #{user.email} starting..."

    # Continue only when doi is pending
    return unless work.doi.nil? || work.doi == DataSet::DOI_PENDING

    if Deepblue::DoiMintingService.mint_doi_for work
      Rails.logger.debug "DoiMintingJob work id #{id} #{user.email} succeeded."
      # do success callback
      if Hyrax.config.callback.set?(:after_doi_success)
        Hyrax.config.callback.run(:after_doi_success, work, user, log.created_at)
      end
    else
      Rails.logger.debug "DoiMintingJob work id #{id} #{user.email} failed."
      # do failure callback
      if Hyrax.config.callback.set?(:after_doi_failure)
        Hyrax.config.callback.run(:after_doi_failure, work, user, log.created_at)
      end
    end
  end

end
