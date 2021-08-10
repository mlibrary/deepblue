# frozen_string_literal: true

module Deepblue

  require_relative '../../app/services/deepblue/fedora_accessible_service'

  class FedoraAccessible

    attr_accessor :accessible, :options, :verbose

    def initialize( options: {} )
      @options = TaskHelper.task_options_parse options
    end

    def run
      verbose = task_options_value( key: 'verbose', default_value: false )
      accessible = FedoraAccessibleService.fedora_accessible?
      puts "Fedora accessible: #{accessible}"
    end

    def task_options_value( key:, default_value: nil, verbose: false )
      TaskHelper.task_options_value( @options, key: key, default_value: default_value, verbose: verbose )
    end

  end

end
