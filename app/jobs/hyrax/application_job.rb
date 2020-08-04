# frozen_string_literal: true

require File.join(Gem::Specification.find_by_name("railties").full_gem_path, "lib/rails/generators/rails/app/templates/app/jobs/application_job.rb")

module Hyrax
  # A common base class for all Hyrax jobs.
  # This allows downstream applications to manipulate all the hyrax jobs by
  # including modules on this class.
  # class ApplicationJob < ActiveJob::Base
  class ApplicationJob < ::ApplicationJob
  end
end
