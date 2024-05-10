# frozen_string_literal: true
# this class is specific to UMich authentication only

require 'devise/strategies/http_header_authenticatable'
module Devise
  module Models
    module HttpHeaderAuthenticatable
      extend ActiveSupport::Concern

      def after_database_authentication
      end

    protected


    end
  end
end
