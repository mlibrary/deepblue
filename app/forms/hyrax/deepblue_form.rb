# frozen_string_literal: truez

module Hyrax

  class DeepblueForm < Hyrax::Forms::WorkForm

    include Deepbluedocs::DefaultWorkFormBehavior

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
