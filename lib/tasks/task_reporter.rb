# frozen_string_literal: true

require_relative './task_pacifier'

module Deepblue

  module TaskReporter
    require_relative './task_reporter'

    attr_accessor :log, :pacifier

    def log
      @log ||= initialize_log
    end

    def pacifier
      @pacifier ||= initialize_pacifier
    end

    protected

      def initialize_log
        Deepblue::TaskLogger.new( STDOUT ).tap { |logger| logger.level = Logger::INFO; Rails.logger = logger }
      end

      def initialize_pacifier
        Deepblue::TaskPacifier.new( out: STDOUT )
      end

  end

end