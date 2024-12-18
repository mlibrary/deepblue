# frozen_string_literal: true

module DeepblueHelper

  # CLEAN_STR_REPLACEMENT_CHAR = "?"
  UTF8 = 'UTF-8'.freeze unless const_defined? :UTF8

  # Replace invalid UTF-8 character sequences with a replacement character
  #
  # Returns self as valid UTF-8.
  def self.clean_str!(str)
    return str if str.encoding.to_s == UTF8
    str.force_encoding("binary").encode(UTF8, :invalid => :replace, :undef => :replace, :replace => '?')
  end

  # Replace invalid UTF-8 character sequences with a replacement character
  #
  # Returns a copy of this String as valid UTF-8.
  def self.clean_str(str)
    clean_str!(str.dup)
  end

  def self.clean_str_needed?( str )
    str.encoding.to_s != UTF8
  end

  def self.display_timestamp( timestamp )
    timestamp = timestamp.to_datetime if timestamp.is_a? Time
    timestamp = DateTime.parse timestamp if timestamp.is_a? String
    if Rails.configuration.datetime_stamp_display_local_time_zone
      timestamp = timestamp.new_offset( Rails.configuration.timezone_offset )
      "#{timestamp.strftime("%Y-%m-%d %H:%M:%S")}"
    else
      "#{timestamp.strftime("%Y-%m-%d %H:%M:%S")} #{timestamp.formatted_offset(false, 'UTC')}"
    end
  end

  def self.human_readable_size( value, precision: 3 )
    ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: precision )
  end

  def self.human_readable_size_str( value, precision: 3 )
    "#{human_readable_size(value)} (#{value} bytes)"
  end

  def user_agent()
    user_agent =  request.env['HTTP_USER_AGENT']
    user_agent
  end

  def users_browser()
    user_agent = user_agent().downcase
    @users_browser ||= begin
      if user_agent.index('msie') && !user_agent.index('opera') && !user_agent.index('webtv')
                    # 'ie'+user_agent[user_agent.index('msie')+5].chr
                    'msie'
      elsif user_agent.index('gecko/')
          'gecko'
      elsif user_agent.index('opera')
          'opera'
      elsif user_agent.index('konqueror')
          'konqueror'
      elsif user_agent.index('ipod')
          'ipod'
      elsif user_agent.index('ipad')
          'ipad'
      elsif user_agent.index('iphone')
          'iphone'
      elsif user_agent.index('chrome/')
          'chrome'
      elsif user_agent.index('applewebkit/')
          'safari'
      elsif user_agent.index('googlebot/')
          'googlebot'
      elsif user_agent.index('msnbot')
          'msnbot'
      elsif user_agent.index('yahoo! slurp')
          'yahoobot'
      elsif user_agent.index('mozilla/5.0 (windows nt 6.3; win64, x64')
          'msie'
      elsif user_agent.index('mozilla/5.0 (windows nt 10.0; win64; x64)')
          'msie'
      #Everything thinks it's mozilla, so this goes last
      elsif user_agent.index('mozilla/')
          'gecko'
      else
          'unknown'
      end
    end

    return @users_browser
  end

end
