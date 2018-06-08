# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/controllers/hyrax/file_sets_controller.rb" )

module Hyrax

  # monkey patch FileSetsController
  class FileSetsController < ApplicationController
    alias_method :monkey_update, :update
    alias_method :monkey_update_metadata, :update_metadata

    def provenance_log_update_after
      # TODO: list updated values deltas
      curation_concern.provenance_update( current_user: current_user )
    end

    def provenance_log_update_before
      # TODO: capture before update values to generate delta
      # curation_concern.provenance_update( current_user: current_user )
    end

    # PATCH /concern/file_sets/:id
    def update
      provenance_log_update_before
      monkey_update
      provenance_log_update_after
    rescue RSolr::Error::Http => error
      flash[:error] = error.message
      logger.error "FileSetsController::update rescued #{error.class}\n\t#{error.message}\n #{error.backtrace.join("\n")}\n\n"
      render action: 'edit'
    end

    def update_metadata
      provenance_log_update_before
      monkey_update_metadata
      provenance_log_update_after
    end

  end

end
