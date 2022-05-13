# frozen_string_literal: true
module Deepblue
  module LoggingIntializationService

    @@_setup_ran = false
    @@_setup_failed = false

    mattr_accessor :suppress_active_support_logging, default: true
    mattr_accessor :suppress_active_support_logging_active_view_render, default: false
    mattr_accessor :suppress_active_support_logging_verbose, default: true

    mattr_accessor :suppress_blacklight_logging, default: false

    @@suppressed_has_run = false

    def self.setup
      return if @@_setup_ran == true
      @@_setup_ran = true
      begin
        yield self
      rescue Exception => e # rubocop:disable Lint/RescueException
        @@_setup_failed = true
      end
    end

    def self.initialize_logging
      run_suppress_active_support_logging if suppress_active_support_logging
      run_suppress_blacklight_logging if suppress_blacklight_logging
      STDOUT.puts if suppress_active_support_logging_verbose
      STDOUT.flush if suppress_active_support_logging_verbose
    end

    def self.puts_active_support_log_subscribers(prefix: '')
      STDOUT.puts "\n#{prefix}List of ActiveSupport::LogSubscriber.subscribers:"
      ActiveSupport::LogSubscriber.subscribers.each do |s|
        STDOUT.puts "-- #{s.to_s} -- #{s.patterns.size} pattern(s)"
        s.patterns.each_with_index do |p,i|
          STDOUT.puts "---- #{i} - #{p}"
        end
      end
    end

    def self.run_suppress_active_support_logging
      return if @@suppressed_has_run
      return unless suppress_active_support_logging
      begin
        puts_active_support_log_subscribers(prefix: '') if suppress_active_support_logging_verbose
        STDOUT.puts "\nRemove specified listeners from list of ActiveSupport::Notifications..." if suppress_active_support_logging_verbose
        notifier = ActiveSupport::Notifications.notifier
        active_fedora = [ "logger.active_fedora",
                          "ldp.active_fedora" ]
        action_cable = [ "transmit_subscription_confirmation.action_cable",
                         "transmit_subscription_rejection.action_cable" ]
        action_view = [ "logger.active_fedora" ]
        action_view_render = [ "render_collection.action_view",
                               "render_partial.action_view",
                               "render_template.action_view" ]
        active_record =   [ "sql.active_record" ]
        unsubscribe_these = []
        unsubscribe_these += active_fedora
        unsubscribe_these += action_cable
        unsubscribe_these += action_view
        unsubscribe_these += action_view_render if suppress_active_support_logging_active_view_render
        unsubscribe_these += active_record
        unsubscribe_these.each do |unsubscribe_id|
          STDOUT.puts "ActiveSupport::Notifications.notifier unsubscribing #{unsubscribe_id}" if suppress_active_support_logging_verbose
          subscribers = notifier.listeners_for( unsubscribe_id )
          count = 0
          subscribers.each { |subscriber| ActiveSupport::Notifications.unsubscribe( subscriber ); count += 1 }
          STDOUT.puts "ActiveSupport::Notifications.notifier unsubscribed #{count} for #{unsubscribe_id}" if count > 0 if suppress_active_support_logging_verbose
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        STDOUT.puts "#{e.class} #{e.message} at #{e.backtrace[0]}"
        STDOUT.flush
      end
      # @@suppressed_has_run = true
    end

    def self.null_logger
      @@null_logger ||= Logger.new("/dev/null")
    end

    def self.run_suppress_blacklight_logging
      # TODO: figure out a way to wrap a logger and change the log level for the wrapper
      return unless suppress_blacklight_logging
      STDOUT.puts "\nSet Blacklight.logger = null_logger" if suppress_active_support_logging_verbose
      Blacklight.logger = null_logger
    end

  end

end
