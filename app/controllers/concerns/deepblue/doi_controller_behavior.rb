# frozen_string_literal: true

module Deepblue

  module DoiControllerBehavior

    mattr_accessor :doi_controller_behavior_debug_verbose,
                   default: ::Deepblue::DoiMintingService.doi_controller_behavior_debug_verbose

    def doi
      msg = doi_mint
      respond_to do |wants|
        # wants.html { redirect_to [main_app, curation_concern], notice: msg }
        wants.html { doi_redirect_after( msg ) }
        wants.json do
          unless Rails.configuration.rest_api_allow_mutate
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          render :show,
                 status: :ok,
                 location: polymorphic_path([main_app, curation_concern])
        end
      end
    end

    def doi_redirect_after( msg )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if doi_controller_behavior_debug_verbose
      redirect_to [main_app, curation_concern], notice: msg
    end

    def doi_minting_enabled?
      ::Deepblue::DoiBehavior.doi_minting_enabled
    end

    def doi_mint
      cc = curation_concern
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( "self", self ),
                                           ::Deepblue::LoggingHelper.obj_class( "curation_concern", cc ),
                                           "curation_concern.id=#{cc.id}",
                                           "curation_concern.depositor=#{cc.depositor}",
                                           "current_user&.email=#{current_user&.email}",
                                           "current_ability&.admin?=#{current_ability&.admin?}",
                                           "curation_concern.doi=#{cc.doi}",
                                           "curation_concern.doi_pending?=#{cc.doi_pending?}",
                                           "curation_concern.doi_minted?=#{cc.doi_minted?}",
                                           "curation_concern.work?=#{cc.work?}",
                                           "" ] if doi_controller_behavior_debug_verbose
      if cc.is_a? SolrDocument
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               ::Deepblue::LoggingHelper.obj_class( "curation_concern", cc ),
                                               "curation_concern.id=#{cc.id}",
                                               "curation_concern is a SolrDocument, find the model",
                                               "" ] if doi_controller_behavior_debug_verbose
        id = cc.id
        cc = PersistHelper.find( id )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern=#{cc}",
                                               "" ] if doi_controller_behavior_debug_verbose
      end
      # Do not mint doi if
      #   one already exists
      #   work file_set count is 0.
      msg = if cc.doi_pending?
              MsgHelper.t( 'data_set.doi_is_being_minted' )
            elsif cc.doi_minted?
              MsgHelper.t( 'data_set.doi_already_exists' )
            elsif cc.work? && cc.file_sets.count < 1
              MsgHelper.t( 'data_set.doi_requires_work_with_files' )
            elsif ( cc.depositor != current_user&.email ) && !current_ability&.admin?
              MsgHelper.t( 'data_set.doi_user_without_access' )
            elsif cc.doi_mint( current_user: current_user, event_note: cc.class.name )
              MsgHelper.t( 'data_set.doi_minting_started' )
            end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                            ::Deepblue::LoggingHelper.obj_class( "self", self ),
                                            ::Deepblue::LoggingHelper.obj_class( "curation_concern", cc ),
                                            "curation_concern.id=#{cc.id}",
                                            "msg=#{msg}",
                                            "" ] if doi_controller_behavior_debug_verbose
      return msg
    end

  end

end
