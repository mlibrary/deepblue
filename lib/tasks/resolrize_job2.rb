# frozen_string_literal: true

require_relative './active_fedora_indexing_reindex_everything2'
require_relative './task_logger'
require_relative '../../app/jobs/hyrax/application_job'

module Deepblue

  class ResolrizeJob2 < ::Hyrax::ApplicationJob

    def perform
      logger = TaskHelper.logger_new
      pacifier = TaskPacifier.new
      ActiveFedora::Base.reindex_everything2( logger: logger, pacifier: pacifier )
    end

  end

end
