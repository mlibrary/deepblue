# this class is specific to UMich authentication only

module Devise
  module Strategies
    class HttpHeaderAuthenticatable < ::Devise::Strategies::Base

      mattr_accessor :http_header_authenticatable_debug_verbose, default: false

      include Devise::Behaviors::HttpHeaderAuthenticatableBehavior

      # Called if the user doesn't already have a rails session cookie
      def valid?
        valid_user?(request.headers)
      end

      def authenticate!
        user = remote_user(request.headers)
        if user.present?
          Rails.logger.debug "[AUTHN] HttpHeaderAuthenticatable#authenticate! succeeded: #{user}" if http_header_authenticatable_debug_verbose
          u = User.find_by_user_key(user)
          if u.nil?
            u = User.create(email: user)
          end
          success!(u)
        else
          Rails.logger.debug '[AUTHN] HttpHeaderAuthenticatable#authenticate! failed.' if http_header_authenticatable_debug_verbose
          fail!
        end
      end

    end
  end
end

Warden::Strategies.add(:http_header_authenticatable, Devise::Strategies::HttpHeaderAuthenticatable)
