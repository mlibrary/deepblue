# frozen_string_literal: true

module DeepblueHelper

	def self.display_timestamp( timestamp )
		timestamp = timestamp.to_datetime if timestamp.is_a? Time
		timestamp = DateTime.parse timestamp if timestamp.is_a? String
		if DeepBlueDocs::Application.config.datetime_stamp_display_local_time_zone
			timestamp = timestamp.new_offset( DeepBlueDocs::Application.config.timezone_offset )
			"#{timestamp.strftime("%Y-%m-%d %H:%M:%S")}"
		else
			"#{timestamp.strftime("%Y-%m-%d %H:%M:%S")} #{timestamp.formatted_offset(false, 'UTC')}"
		end
	end

	def self.human_readable_size( value, precision: 3 )
    ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: precision )
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
