# frozen_string_literal: true

require 'tasks/active_fedora_indexing_reindex_everything2'
require 'tasks/task_logger'

module Deepblue

  class ResolrizeJob2 < Hyrax::ApplicationJob

    def perform
      logger = TaskHelper.logger_new
      pacifier = TaskPacifier.new
      ActiveFedora::Base.reindex_everything2( logger: logger, pacifier: pacifier )
    end

  end

end
