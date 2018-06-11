# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/controllers/hyrax/file_sets_controller.rb" )

module Hyrax

  # monkey patch FileSetsController
  class FileSetsController < ApplicationController
    alias_method :monkey_update, :update
    alias_method :monkey_update_metadata, :update_metadata

    before_action :provenance_log_destroy,       only: [:destroy]
    before_action :provenance_log_update_before, only: [:update]

    after_action :provenance_log_create,         only: [:create]
    after_action :provenance_log_update_after,   only: [:update]

    def provenance_log_create
      curation_concern.provenance_create( current_user: current_user )
    end

    def provenance_log_destroy
      curation_concern.provenance_destroy( current_user: current_user )
    end

    def provenance_log_update_after
      curation_concern.provenance_log_update_after( current_user: current_user )
    end

    def provenance_log_update_before
      curation_concern.provenance_log_update_before( current_user: current_user )
    end

    # # PATCH /concern/file_sets/:id
    # def update
    #   curation_concern.provenance_log_update_before( current_user: current_user, event_note: 'from #update' )
    #   monkey_update
    #   curation_concern.provenance_log_update_after( current_user: current_user, event_note: 'from #update' )
    # rescue RSolr::Error::Http => error
    #   flash[:error] = error.message
    #   logger.error "FileSetsController::update rescued #{error.class}\n\t#{error.message}\n #{error.backtrace.join("\n")}\n\n"
    #   render action: 'edit'
    # end
    #
    # def update_metadata
    #   curation_concern.provenance_log_update_before( current_user: current_user, event_note: 'from #update_metadata' )
    #   monkey_update_metadata
    #   curation_concern.provenance_log_update_after( current_user: current_user, event_note: 'from #update_metadata' )
    # end

  end

end
