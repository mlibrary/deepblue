# frozen_string_literal: true

require_relative '../../helpers/deepblue/jobs_helper'

class ::Deepblue::DeepblueJob < ::Hyrax::ApplicationJob

  # A common base class for all Hyrax jobs.
  # This allows downstream applications to manipulate all the hyrax jobs by
  # including modules on this class.

  include JobHelper # see JobHelper for:

  mattr_accessor :deepblue_job_debug_verbose, default: ::Deepblue::JobTaskHelper.deepblue_job_debug_verbose

  # make the job_or_instantiate method public by copying its internals
  # see: active_job/enqueuing.rb
  # hyrax2 / ruby 2 version # def self.job_or_instantiate(**args)
  def self.job_or_instantiate(*args)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args.pretty_inspect}",
                                           "" ] if deepblue_job_debug_verbose
    # hyrax2 / ruby 2 version # rv = args.first.is_a?(self) ? args.first : new(*args)
    rv = args.first.is_a?(self) ? args.first : new(*args)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "rv=#{rv.pretty_inspect}",
                                           "" ] if deepblue_job_debug_verbose
    return rv
  end

  # def perform_now
  # This is broken, it can't find the super.perform_now
  #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
  #                                          ::Deepblue::LoggingHelper.called_from,
  #                                          "" ] if deepblue_job_debug_verbose
  #   super.perform_now
  #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
  #                                          ::Deepblue::LoggingHelper.called_from,
  #                                          "" ] if deepblue_job_debug_verbose
  # end

end
