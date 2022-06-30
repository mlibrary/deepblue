# frozen_string_literal: true

# monkey override
# monkey note: exceptions won't match when they are in the gem only

module Hyrax
  require 'active_fedora/errors'

  # Generic Hyrax exception class.
  class HyraxError < StandardError; end

  # Error that is raised when an active workflow can't be found
  class MissingWorkflowError < HyraxError; end

  class WorkflowAuthorizationException < HyraxError; end

  class AnonymousError < HyraxError; end

  class SingleUseError < HyraxError; end

  class SingleMembershipError < HyraxError; end

  class ObjectNotFoundError < ActiveFedora::ObjectNotFoundError; end

end
