# frozen_string_literal: truez

module Hyrax

  class DeepblueForm < Hyrax::Forms::WorkForm

    include Deepbluedocs::DefaultWorkFormBehavior

    # hyrax-orcid begin
    include ::Hyrax::Orcid::WorkFormBehavior
    # hyrax-orcid end

    def data_set?
      false
    end

    def dissertation?
      false
    end

    def generic_work?
      false
    end

  end

end
