# frozen_string_literal: true
module Deepblue
  module LoggingIntializationService

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

    mattr_accessor :suppress_active_support_logging, default: false
    mattr_accessor :suppress_active_support_logging_verbose, default: false
    mattr_accessor :suppress_blacklight_logging, default: false

    mattr_accessor :active_support_list_ids, default: false
    mattr_accessor :active_support_suppressed_ids, default: [ "ldp.active_fedora",
                                                              "logger.active_fedora",
                                                              "render_collection.action_view",
                                                              "render_partial.action_view",
                                                              "render_template.action_view",
                                                              "sql.active_record",
                                                              "transmit_subscription_confirmation.action_cable",
                                                              "transmit_subscription_rejection.action_cable" ]

    # @@suppressed_has_run = false

    def self.initialize_logging(debug_verbose: false)
      @@debug_verbose = debug_verbose || suppress_active_support_logging_verbose
      run_suppress_active_support_logging
      run_suppress_blacklight_logging
      STDOUT.puts if @@debug_verbose
      STDOUT.flush if @@debug_verbose
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
      return unless suppress_active_support_logging
      debug_verbose = @@debug_verbose || suppress_active_support_logging_verbose
      begin
        puts_active_support_log_subscribers(prefix: 'Before ') if debug_verbose && active_support_list_ids
        STDOUT.puts "\nRemove specified listeners from list of ActiveSupport::Notifications..." if debug_verbose
        notifier = ActiveSupport::Notifications.notifier
        active_support_suppressed_ids.each do |unsubscribe_id|
          STDOUT.puts "ActiveSupport::Notifications.notifier unsubscribing #{unsubscribe_id}" if debug_verbose
          subscribers = notifier.listeners_for( unsubscribe_id )
          count = 0
          subscribers.each { |subscriber| ActiveSupport::Notifications.unsubscribe( subscriber ); count += 1 }
          STDOUT.puts "ActiveSupport::Notifications.notifier unsubscribed #{count} for #{unsubscribe_id}" if count > 0 if debug_verbose
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
      debug_verbose = @@debug_verbose || suppress_active_support_logging_verbose
      STDOUT.puts "\nSet Blacklight.logger = null_logger" if debug_verbose
      Blacklight.logger = null_logger
    end

  end

end
