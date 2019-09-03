# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/controllers/hyrax/file_sets_controller.rb" )

module Hyrax

  # monkey patch FileSetsController
  class FileSetsController < ApplicationController

    PARAMS_KEY = 'file_set'
    self.show_presenter = Hyrax::DsFileSetPresenter

    alias_method :monkey_attempt_update, :attempt_update
    # alias_method :monkey_update_metadata, :update_metadata

    before_action :provenance_log_destroy,       only: [:destroy]
    before_action :provenance_log_update_before, only: [:update]

    after_action :provenance_log_create,         only: [:create]
    after_action :provenance_log_update_after,   only: [:update]

    protect_from_forgery with: :null_session,    only: [:display_provenance_log]

    ## Provenance log

    def provenance_log_create
      curation_concern.provenance_create( current_user: current_user, event_note: 'FileSetsController' )
    end

    def provenance_log_destroy
      curation_concern.provenance_destroy( current_user: current_user, event_note: 'FileSetsController' )
    end

    def provenance_log_update_after
      curation_concern.provenance_log_update_after( current_user: current_user,
                                                    # event_note: 'FileSetsController.provenance_log_update_after',
                                                    update_attr_key_values: @update_attr_key_values )
    end

    def provenance_log_update_before
      @update_attr_key_values = curation_concern.provenance_log_update_before( form_params: params[PARAMS_KEY].dup )
    end

    ## end Provenance log

    ## display provenance log

    def display_provenance_log
      # load provenance log for this work
      file_path = Deepblue::ProvenancePath.path_for_reference( curation_concern.id )
      Deepblue::LoggingHelper.bold_debug [ "DataSetsController", "display_provenance_log", file_path ]
      Deepblue::ProvenanceLogService.entries( curation_concern.id, refresh: true )
      # continue on to normal display
      redirect_to [main_app, curation_concern]
    end

    def display_provenance_log_enabled?
      true
    end

    def provenance_log_entries_present?
      provenance_log_entries.present?
    end

    ## end display provenance log

    protected

      def attempt_update
        # Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                      Deepblue::LoggingHelper.called_from,
        #                                      "current_user=#{current_user}",
        #                                      Deepblue::LoggingHelper.obj_class( "actor", actor ) ]
        if wants_to_revert?
          Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "current_user=#{current_user}",
                                               Deepblue::LoggingHelper.obj_class( "actor", actor ),
                                               "wants to revert" ]
          actor.revert_content(params[:revision])
        elsif params.key?(:file_set)
          if params[:file_set].key?(:files)
            Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                 Deepblue::LoggingHelper.called_from,
                                                 "current_user=#{current_user}",
                                                 Deepblue::LoggingHelper.obj_class( "actor", actor ),
                                                 "actor.update_content" ]
            actor.update_content(params[:file_set][:files].first)
          else
            Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                 Deepblue::LoggingHelper.called_from,
                                                 "current_user=#{current_user}",
                                                 "update_metadata" ]
            update_metadata
          end
        end
      end

      def presenter
        @presenter ||= begin
          curation_concern = search_result_document( params )
          show_presenter.new( curation_concern, current_ability, request )
        end
      end

      def show_presenter
        Hyrax::DsFileSetPresenter
      end

      def search_result_document( search_params )
        _, document_list = search_results( search_params )
        return document_list.first unless document_list.empty?
        # document_not_found!
        raise CanCan::AccessDenied
      rescue Blacklight::Exceptions::RecordNotFound => e
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "e=#{e}",
                                               "" ]
        begin
          # check with Fedora to see if the requested id was deleted
          id = params[:id]
          ActiveFedora::Base.find( id )
        rescue Ldp::Gone => gone
          # it was deleted
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "gone=#{gone.class} #{gone.message} at #{gone.backtrace[0]}",
                                                 "" ]
          # okay, since this looks like a deleted curation concern, we can check the provenance log
          # if admin, redirect to the provenance log controller
          if current_ability.admin?
            url = Rails.application.routes.url_helpers.url_for( only_path: true,
                                                                action: 'show',
                                                                controller: 'provenance_log',
                                                                id: id )
            return redirect_to( url, error: "#{id} was deleted." )
          end
        rescue ActiveFedora::ObjectNotFoundError => e2
          # nope, never existed
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "e2=#{e2.class} #{e2.message} at #{e2.backtrace[0]}",
                                                 "" ]
        end
        raise CanCan::AccessDenied
      end

  end

end
