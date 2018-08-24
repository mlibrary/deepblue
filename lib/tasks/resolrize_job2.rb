# frozen_string_literal: true

require 'tasks/active_fedora_indexing_reindex_everything2'
require 'tasks/task_logger'

module Deepblue

  class ResolrizeJob2 < ApplicationJob

    def perform
      logger = TaskLogger.new(STDOUT).tap { |log| log.level = Logger::INFO; Rails.logger = log } # rubocop:disable Style/Semicolon
      pacifier = TaskPacifier.new
      ActiveFedora::Base.reindex_everything2( logger: logger, pacifier: pacifier )
    end

  end

end
