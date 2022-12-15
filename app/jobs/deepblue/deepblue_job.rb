# frozen_string_literal: true

require_relative '../../helpers/deepblue/jobs_helper'

class ::Deepblue::DeepblueJob < ::Hyrax::ApplicationJob

  # A common base class for all Hyrax jobs.
  # This allows downstream applications to manipulate all the hyrax jobs by
  # including modules on this class.

  include JobHelper # see JobHelper for:

  mattr_accessor :deepblue_job_debug_verbose, default: ::Deepblue::JobTaskHelper.deepblue_job_debug_verbose

end
