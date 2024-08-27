# frozen_string_literal: true
# Reviewed: hyrax4

module Hyrax
  # A common base class for all Hyrax jobs.
  # This allows downstream applications to manipulate all the hyrax jobs by
  # including modules on this class.
  class ApplicationJob < ActiveJob::Base
  # hyrax4 # class ApplicationJob < ::ApplicationJob
    before_enqueue do |job|
      job.arguments.map! do |arg|
        case arg
        when Valkyrie::Resource
          Hyrax::ValkyrieGlobalIdProxy.new(resource: arg)
        else
          arg
        end
      end
    end
  end
end
