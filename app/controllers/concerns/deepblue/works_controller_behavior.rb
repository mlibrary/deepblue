module Deepblue
  module WorksControllerBehavior
    extend ActiveSupport::Concern
    #in umrdr
    #include Hyrax::Controller
    include Hyrax::WorksControllerBehavior

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
