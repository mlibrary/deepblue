# frozen_string_literal: true

module Deepblue

  module WorksControllerBehavior
    extend ActiveSupport::Concern
    #in umrdr
    #include Hyrax::Controller
    include Hyrax::WorksControllerBehavior
    include Deepblue::ControllerWorkflowEventBehavior
    include Deepblue::DoiControllerBehavior
    include Deepblue::IngestAppendScriptControllerBehavior

    def after_update_response
      if curation_concern.file_sets.present?
        return redirect_to main_app.copy_access_hyrax_permission_path(curation_concern)  if permissions_changed?
        return redirect_to main_app.confirm_hyrax_permission_path(curation_concern) if curation_concern.visibility_changed?
      end
      respond_to do |wants|
        wants.html { redirect_to [main_app, curation_concern], notice: "Work \"#{curation_concern}\" successfully updated." }
        wants.json { render :show, status: :ok, location: polymorphic_path([main_app, curation_concern]) }
      end
    end

    # override curation concerns, add form fields values
    def build_form
      super
      # Set up the multiple parameters for the date coverage attribute in the form
      cov_date = Date.edtf(@form.date_coverage)
      cov_params = Dataset::DateCoverageService.interval_to_params cov_date
      @form.merge_date_coverage_attributes! cov_params
    end

    # Finds a solr document matching the id and sets @presenter
    # @raise CanCan::AccessDenied if the document is not found or the user doesn't have access to it.
    def show
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ]
      @user_collections = user_collections

      respond_to do |wants|
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                               "wants.format=#{wants.format}",
                                               "" ]
        wants.html do
          presenter && parent_presenter
        end
        wants.json do
          # load and authorize @curation_concern manually because it's skipped for html
          @curation_concern = _curation_concern_type.find(params[:id]) unless curation_concern
          presenter
          authorize! :show, @curation_concern
          render :show, status: :ok
        end
        additional_response_formats(wants)
        wants.ttl do
          render body: presenter.export_as_ttl, content_type: 'text/turtle'
        end
        wants.jsonld do
          render body: presenter.export_as_jsonld, content_type: 'application/ld+json'
        end
        wants.nt do
          render body: presenter.export_as_nt, content_type: 'application/n-triples'
        end
      end
    end


  end

end
