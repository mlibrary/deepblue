# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_task'
  require_relative '../../app/services/deepblue/globus_integration_service'

  class GlobusErrorsReport < AbstractTask

    attr_accessor :options

    def initialize( options: )
      super( options: options )
    end

    def run
      puts "ARGV=#{ARGV}"
      puts "options=#{options}"
      GlobusIntegrationService.globus_errors_report( options: options, debug_verbose: verbose, rake_task: true )
    end

  end

end
