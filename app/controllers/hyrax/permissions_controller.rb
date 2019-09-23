# frozen_string_literal: true

module Hyrax

  class PermissionsController < ApplicationController
    helper_method :curation_concern

    def confirm
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "" ]
      # intentional noop to display default view
      embargo_release_date = curation_concern.embargo_release_date if curation_concern.respond_to? :embargo_release_date
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "curation_concern.embargo_release_date=#{embargo_release_date}",
                                           "" ]
      copy unless DeepBlueDocs::Application.config.embargo_allow_children_unembargo_choice
    end

    def copy
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "" ]
      authorize! :edit, curation_concern
      VisibilityCopyJob.perform_later(curation_concern)
      flash_message = I18n.t("hyrax.embargo.copy_visibility_flash_message")
      redirect_to [main_app, curation_concern], notice: flash_message
    end

    def confirm_access
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "" ]
      # intentional noop to display default view
    end

    def copy_access
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "" ]
      authorize! :edit, curation_concern
      # copy visibility
      VisibilityCopyJob.perform_later(curation_concern)

      # copy permissions
      InheritPermissionsJob.perform_later(curation_concern)
      redirect_to [main_app, curation_concern], notice: I18n.t("hyrax.upload.change_access_flash_message")
    end

    def curation_concern
      @curation_concern ||= ActiveFedora::Base.find(params[:id])
    end

  end

end
