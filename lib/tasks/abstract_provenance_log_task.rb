# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_log_task'

  class AbstractProvenanceLogTask < AbstractLogTask

    def initialize( options: )
      super( options: options )
    end

    def initialize_input
      task_options_value( key: 'input', default_value: Rails.configuration.provenance_log_path )
    end

  end

end
