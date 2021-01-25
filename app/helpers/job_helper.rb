# frozen_string_literal: true

module JobHelper

  def job_options_keys_found
    @job_options_keys_found ||= []
  end

  def job_options_value( options, key:, default_value: nil, verbose: false )
    # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                       "options=#{options}",
    #                                       "key=#{key}",
    #                                       "default_value=#{default_value}",
    #                                       "verbose=#{verbose}",
    #                                        "" ]
    return default_value if options.blank?
    return default_value unless options.key? key
    # if [true, false].include? default_value
    #   return options[key].to_bool
    # end
    @job_options_keys_found ||= []
    @job_options_keys_found << key
    ::Deepblue::LoggingHelper.debug "set key #{key} to #{options[key]}" if verbose
    return options[key]
  end

end