# frozen_string_literal: true

module Hyrax

  class CollectionsController < DeepblueController

    EVENT_NOTE = 'CollectionsController'
    PARAMS_KEY = 'collection'

    include Hyrax::CollectionsControllerBehavior
    # include Deepblue::CollectionsControllerBehavior
    include BreadcrumbsForCollections

    before_action :email_rds_destroy,            only: [:destroy]
    before_action :provenance_log_destroy,       only: [:destroy]
    before_action :provenance_log_update_before, only: [:update]
    before_action :visiblity_changed,            only: [:update]

    after_action :email_rds_create,                only: [:create]
    after_action :provenance_log_create,           only: [:create]
    after_action :visibility_changed_update,       only: [:update]
    after_action :provenance_log_update_after,     only: [:update]

    with_themed_layout :decide_layout
    load_and_authorize_resource except: %i[index show create], instance_name: :collection

    # Renders a JSON response with a list of files in this collection
    # This is used by the edit form to populate the thumbnail_id dropdown
    def files
      result = form.select_files.map do |label, id|
        { id: id, text: label }
      end
      render json: result
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
      curation_concern.provenance_log_update_after( current_user: current_user,
                                                    # event_note: 'CollectionsController.provenance_log_update_after',
                                                    update_attr_key_values: @update_attr_key_values )
    end

    def provenance_log_update_before
      @update_attr_key_values = curation_concern.provenance_log_update_before( form_params: params[PARAMS_KEY].dup )
    end

    ## end Provenance log

    ## visibility / publish

    def visiblity_changed
      if visibility_to_private?
        mark_as_set_to_private
      elsif visibility_to_public?
        mark_as_set_to_public
      end
    end

    def visibility_changed_update
      if curation_concern.private? && @visibility_changed_to_private
        provenance_log_unpublish
        email_rds_unpublish
      elsif curation_concern.public? && @visibility_changed_to_public
        provenance_log_publish
        email_rds_publish
      end
    end

    def visibility_to_private?
      return false if curation_concern.private?
      params[PARAMS_KEY]['visibility'] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    def visibility_to_public?
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
