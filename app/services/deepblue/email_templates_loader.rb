# frozen_string_literal: true

module Deepblue

  class EmailTemplatesLoader

    def initialize
    end

    def load( debug_verbose: false )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if debug_verbose
      ::Deepblue::WorkViewContentService.load_email_templates( debug_verbose: debug_verbose )
    end

  end

end
