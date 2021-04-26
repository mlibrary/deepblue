# frozen_string_literal: true

# monkey add method ahoy_matey lib/ahoy/tracker.rb
# https://github.com/ankane/ahoy/blob/master/lib/ahoy/tracker.rb
# https://github.com/mlibrary/deepblue/blob/master/lib/ahoy/tracker.rb
require File.join( Gem::Specification.find_by_name( "ahoy_matey" ).full_gem_path, "lib/ahoy/tracker.rb" )

require_relative "../../app/services/deepblue/analytics_integration_service"

module Ahoy

  class Tracker

    mattr_accessor :ahoy_tracker_debug_verbose, default: ::Deepblue::AnalyticsIntegrationService.ahoy_tracker_debug_verbose

    def track( name, properties = {}, options = {} )
      cc_id = find_cc_id( name, properties )
      track_with_id( name, cc_id, properties, options )
    end

    def find_cc_id( name, properties )
      cc_id = properties["id"] if properties.has_key? "id"
      cc_id = properties["ID"] if cc_id.blank? && properties.has_key?( "ID" )
      cc_id = nil if cc_id.present? && 9 == cc_id.to_s.length # really only care about curation concern ids, and they have a length of 9
      return cc_id
    end

    def track_with_id( name, cc_id = nil, properties = {}, options = {} )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "name=#{name}",
                                             "cc_id=#{cc_id}",
                                             "properties=#{properties}",
                                             "options=#{options}",
                                             "" ] if ahoy_tracker_debug_verbose
      if exclude?
        debug "Event excluded"
      elsif missing_params?
        debug "Missing required parameters"
      else
        data = {
            visit_token: visit_token,
            user_id: user.try(:id),
            name: name.to_s,
            properties: properties,
            time: trusted_time(options[:time]),
            event_id: options[:id] || generate_id,
            cc_id: cc_id  # monkey: add the curation concern id, only change other than debug above
        }.select { |_, v| v }

        @store.track_event(data)
      end
      true
    rescue => e
      report_exception(e)
    end

  end

end
