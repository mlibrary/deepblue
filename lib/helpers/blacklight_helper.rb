# frozen_string_literal: true
# Added: hyrax4
# monkey - copied up from blacklight gem because the blacklight helpers were not being found

require_relative './blacklight/blacklight_helper_behavior'

module BlacklightHelper
  include ::Blacklight::BlacklightHelperBehavior
end
