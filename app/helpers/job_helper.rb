# frozen_string_literal: true

module JobHelper

  def job_options_value(options, key:, default_value: nil, verbose: false )
    return default_value if options.blank?
    return default_value unless options.key? key
    # if [true, false].include? default_value
    #   return options[key].to_bool
    # end
    ::Deepblue::LoggingHelper.debug "set key #{key} to #{options[key]}" if verbose
    return options[key]
  end

end