# frozen_string_literal: true

class DoiMintingJob < ApplicationJob
  queue_as :doi_minting

  def perform(id)
    work = ActiveFedora::Base.find(id)
    user = User.find_by_user_key(work.depositor)

    # Continue only when doi is pending
    return unless work.doi.nil? || work.doi == DataSet::DOI_PENDING

    if Dataset::DoiMintingService.mint_doi_for work
      # do success callback
      if Hyrax.config.callback.set?( :after_doi_success )
        Hyrax.config.callback.run( :after_doi_success, work, user, log.created_at )
      end
    elsif Hyrax.config.callback.set?( :after_doi_failure )
      # do failure callback
      Hyrax.config.callback.run( :after_doi_failure, work, user, log.created_at )
    end
  end

end
