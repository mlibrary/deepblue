# frozen_string_literal: true

module Deepblue

  # require 'jira-ruby' # https://github.com/sumoheavy/jira-ruby

  module TeamdynamixHelper
    extend ActionView::Helpers::TranslationHelper

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

  end

end
