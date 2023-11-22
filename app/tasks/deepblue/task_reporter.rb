# frozen_string_literal: true

module Deepblue

  module TaskReporter

    attr_accessor :log, :pacifier

    def log
      @log ||= initialize_log
    end

    def pacifier
      @pacifier ||= initialize_pacifier
    end

    protected

      def initialize_log
        Deepblue::TaskLogger.new( STDOUT ).tap do |logger|
          logger.level = Logger::INFO
          Rails.logger = logger
        end
      end

      def initialize_pacifier
        Deepblue::TaskPacifier.new( out: STDOUT )
      end

  end

end
