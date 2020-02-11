# frozen_string_literal: true

module Deepblue

  module DoiControllerBehavior

    ## DOI

    def doi
      doi_mint
      respond_to do |wants|
        wants.html { redirect_to [main_app, curation_concern] }
        wants.json do
          render :show,
                 status: :ok,
                 location: polymorphic_path([main_app, curation_concern])
        end
      end
    end

    def doi_minting_enabled?
      ::Deepblue::DoiBehavior::DOI_MINTING_ENABLED
    end

    def doi_mint
      # Do not mint doi if
      #   one already exists
      #   work file_set count is 0.
      if curation_concern.doi_pending?
        flash[:notice] = MsgHelper.t( 'data_set.doi_is_being_minted' )
      elsif curation_concern.doi_minted?
        flash[:notice] = MsgHelper.t( 'data_set.doi_already_exists' )
      elsif curation_concern.work? && curation_concern.file_sets.count < 1
        flash[:notice] = MsgHelper.t( 'data_set.doi_requires_work_with_files' )
      elsif ( curation_concern.depositor != current_user.email ) && !current_ability.admin?
        flash[:notice] = MsgHelper.t( 'data_set.doi_user_without_access' )
      elsif curation_concern.doi_mint( current_user: current_user, event_note: curation_concern.class.name )
        flash[:notice] = MsgHelper.t( 'data_set.doi_minting_started' )
      end
    end

    # def mint_doi_enabled?
    #   true
    # end

    ## end DOI

  end

end
