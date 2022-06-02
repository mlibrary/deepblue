# frozen_string_literal: true

module BrowseEverything
  class Browser

    mattr_accessor :browse_everything_browser_debug_verbose,
                   default: ::BrowseEverythingIntegrationService.browse_everything_browser_debug_verbose

    attr_reader :providers

    def initialize(opts = {})
      url_options = {}
      if opts.key?(:url_options)
        url_options = opts.delete(:url_options)
      else
        url_options = opts
        opts = BrowseEverything.config
      end

      @providers = ActiveSupport::HashWithIndifferentAccess.new
      opts.each_pair do |driver_key, config|
        begin
          driver = driver_key.to_s
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "driver=#{driver}",
                                                 "config[:driver]=#{config[:driver]}",
                                                 "" ] if browse_everything_browser_debug_verbose
          driver_klass = BrowseEverything::Driver.const_get((config[:driver] || driver).camelize.to_sym)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "driver_klass=#{driver_klass}",
                                                 "" ] if browse_everything_browser_debug_verbose
          @providers[driver_key] = driver_klass.new(config.merge(url_options: url_options))
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@providers[driver_key]=#{@providers[driver_key]}",
                                                 "" ] if browse_everything_browser_debug_verbose
        rescue NameError => e
          Rails.logger.warn "Unknown provider: #{driver} -- #{e}\n+#{e.backtrace[1..25].join("\n")}" # monkey
        end
      end
    end

    def first_provider
      @providers.to_hash.each_value.to_a.first
    end
  end
end
