# frozen_string_literal: true

module Hyrax

  class CollectionsController < DeepblueController

    EVENT_NOTE = 'Hyrax::CollectionsController'
    PARAMS_KEY = 'collection'

    include Hyrax::CollectionsControllerBehavior
    # include Deepblue::CollectionsControllerBehavior
    include BreadcrumbsForCollections

    before_action :deepblue_collections_controller_debug

    before_action :email_rds_destroy,            only: [:destroy]
    before_action :provenance_log_destroy,       only: [:destroy]
    before_action :provenance_log_update_before, only: [:update]
    before_action :visiblity_changed,            only: [:update]

    after_action :email_rds_create,              only: [:create]
    after_action :provenance_log_create,         only: [:create]
    after_action :provenance_log_update_after,   only: [:update]
    after_action :visibility_changed_update,     only: [:update]

    protect_from_forgery with: :null_session,    only: [:display_provenance_log]

    with_themed_layout :decide_layout
    load_and_authorize_resource except: %i[index show create], instance_name: :collection

    def deepblue_collections_controller_debug
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "params=#{params}" ]
    end

    # Renders a JSON response with a list of files in this collection
    # This is used by the edit form to populate the thumbnail_id dropdown
    def files
      result = form.select_files.map do |label, id|
        { id: id, text: label }
      end
      render json: result
    end

    def curation_concern
      @collection ||= ActiveFedora::Base.find(params[:id])
    end

    ## email

    def email_rds_create
      curation_concern.email_rds_create( current_user: current_user,
                                         event_note: "created by #{curation_concern.depositor}" )
    end

    def email_rds_destroy
      curation_concern.email_rds_destroy( current_user: current_user )
    end

    def email_rds_publish
      curation_concern.email_rds_publish( current_user: current_user )
    end

    def email_rds_unpublish
      curation_concern.email_rds_unpublish( current_user: current_user )
    end

    ## end email

    ## Provenance log

    def provenance_log_create
      curation_concern.provenance_create( current_user: current_user, event_note: EVENT_NOTE )
    end

    def provenance_log_destroy
      curation_concern.provenance_destroy( current_user: current_user, event_note: EVENT_NOTE )
    end

    def provenance_log_publish
      curation_concern.provenance_publish( current_user: current_user, event_note: EVENT_NOTE )
    end

    def provenance_log_unpublish
      curation_concern.provenance_unpublish( current_user: current_user, event_note: EVENT_NOTE )
    end

    def provenance_log_update_after
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ]
      curation_concern.provenance_log_update_after( current_user: current_user,
                                                    # event_note: 'CollectionsController.provenance_log_update_after',
                                                    update_attr_key_values: @update_attr_key_values )
    end

    def provenance_log_update_before
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "@update_attr_key_values=#{@update_attr_key_values}",
      #                                        "" ]
      return unless @update_attr_key_values.nil?
      @update_attr_key_values = curation_concern.provenance_log_update_before( form_params: params[PARAMS_KEY].dup )
    end

    ## end Provenance log

    ## display provenance log

    def display_provenance_log
      # load provenance log for this work
      id = @collection.id # curation_concern.id
      file_path = Deepblue::ProvenancePath.path_for_reference( id )
      Deepblue::LoggingHelper.bold_debug [ "CollectionsController", "display_provenance_log", file_path ]
      Deepblue::ProvenanceLogService.entries( id, refresh: true )
      # continue on to normal display
      #redirect_to [main_app, curation_concern]
      redirect_to :back
    end

    def display_provenance_log_enabled?
      true
    end

    def provenance_log_entries_present?
      provenance_log_entries.present?
    end

    ## end display provenance log

    ## visibility / publish

    def visiblity_changed
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ]
      @update_attr_key_values = curation_concern.provenance_log_update_before( form_params: params[PARAMS_KEY].dup )
      if visibility_to_private?
        mark_as_set_to_private
      elsif visibility_to_public?
        mark_as_set_to_public
      end
    end

    def visibility_changed_update
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ]
      if curation_concern.private? && @visibility_changed_to_private
        provenance_log_unpublish
        email_rds_unpublish
      elsif curation_concern.public? && @visibility_changed_to_public
        provenance_log_publish
        email_rds_publish
      end
    end

    def visibility_to_private?
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ]
      return false if curation_concern.private?
      params[PARAMS_KEY]['visibility'] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    def visibility_to_public?
      # ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                        Deepblue::LoggingHelper.called_from,
      #                                        Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ]
      return false if curation_concern.public?
      params[PARAMS_KEY]['visibility'] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    def mark_as_set_to_private
      @visibility_changed_to_public = false
      @visibility_changed_to_private = true
    end

    def mark_as_set_to_public
      @visibility_changed_to_public = true
      @visibility_changed_to_private = false
    end

    ## end visibility / publish

    private

      def form
        @form ||= form_class.new( @collection, current_ability, repository )
      end

      def decide_layout
        layout = case action_name
                 when 'show'
                   '1_column'
                 else
                   'dashboard'
                 end
        File.join( theme, layout )
      end

  end

end
