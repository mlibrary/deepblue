module Deepblue
  module WorksControllerBehavior
    extend ActiveSupport::Concern
    #in umrdr
    #include Hyrax::Controller
    include Hyrax::WorksControllerBehavior

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

  end
end
