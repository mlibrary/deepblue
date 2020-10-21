# frozen_string_literal: true

# monkey add method ahoy_matey lib/ahoy/tracker.rb
require File.join( Gem::Specification.find_by_name( "ahoy_matey" ).full_gem_path, "lib/ahoy/tracker.rb" )

module Ahoy

  class Tracker

    AHOY_TRACKER_DEBUG_VERBOSE = true

    def track_with_id( name, cc_id = nil, properties = {}, options = {} )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "name=#{name}",
                                             "cc_id=#{cc_id}",
                                             "properties=#{properties}",
                                             "options=#{options}",
                                             "" ] if AHOY_TRACKER_DEBUG_VERBOSE
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
            cc_id: cc_id
        }.select { |_, v| v }

        @store.track_event(data)
      end
      true
    rescue => e
      report_exception(e)
    end

  end

end
