# frozen_string_literal: true

module Deepblue

  module DoiControllerBehavior

    mattr_accessor :doi_controller_behavior_debug_verbose, default: false

    def doi
      msg = doi_mint
      respond_to do |wants|
        wants.html { redirect_to [main_app, curation_concern], notice: msg }
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

    def doi_minting_enabled?
      ::Deepblue::DoiBehavior::DOI_MINTING_ENABLED
    end

    def doi_mint
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( "self", self ),
                                           ::Deepblue::LoggingHelper.obj_class( "curation_concern", curation_concern ),
                                           "curation_concern.id=#{curation_concern.id}",
                                           "curation_concern.depositor=#{curation_concern.depositor}",
                                           "current_user.email=#{current_user.email}",
                                           "current_ability.admin?=#{current_ability.admin?}",
                                           "curation_concern.doi=#{curation_concern.doi}",
                                           "curation_concern.doi_pending?=#{curation_concern.doi_pending?}",
                                           "curation_concern.doi_minted?=#{curation_concern.doi_minted?}",
                                           "curation_concern.work?=#{curation_concern.work?}",
                                           "" ] if doi_controller_behavior_debug_verbose
      # Do not mint doi if
      #   one already exists
      #   work file_set count is 0.
      msg = if curation_concern.doi_pending?
              MsgHelper.t( 'data_set.doi_is_being_minted' )
            elsif curation_concern.doi_minted?
              MsgHelper.t( 'data_set.doi_already_exists' )
            elsif curation_concern.work? && curation_concern.file_sets.count < 1
              MsgHelper.t( 'data_set.doi_requires_work_with_files' )
            elsif ( curation_concern.depositor != current_user.email ) && !current_ability.admin?
              MsgHelper.t( 'data_set.doi_user_without_access' )
            elsif curation_concern.doi_mint( current_user: current_user, event_note: curation_concern.class.name )
              MsgHelper.t( 'data_set.doi_minting_started' )
            end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                            ::Deepblue::LoggingHelper.obj_class( "self", self ),
                                            ::Deepblue::LoggingHelper.obj_class( "curation_concern", curation_concern ),
                                            ::Deepblue::LoggingHelper.obj_class( "curation_concern", curation_concern ),
                                            "curation_concern.id=#{curation_concern.id}",
                                            "msg=#{msg}",
                                            "" ] if doi_controller_behavior_debug_verbose
      return msg
    end

  end

end
