# frozen_string_literal: true
#
module Deepblue

  module InitializationConstants

    DOWNLOAD = 'download'.freeze unless const_defined? :DOWNLOAD
    LOCAL = 'local'.freeze unless const_defined? :LOCAL
    PREP = 'prep'.freeze unless const_defined? :PREP
    PRODUCTION = 'production'.freeze unless const_defined? :PRODUCTION
    STAGING = 'staging'.freeze unless const_defined? :STAGING
    TEST = 'test'.freeze unless const_defined? :TEST
    TESTING = 'testing'.freeze unless const_defined? :TESTING
    UNKNOWN = 'unknown'.freeze unless const_defined? :UNKNOWN

    HOSTNAME_LOCAL = 'deepblue.local'.freeze unless const_defined? :HOSTNAME_LOCAL
    HOSTNAME_PROD = 'deepblue.lib.umich.edu'.freeze unless const_defined? :HOSTNAME_PROD
    HOSTNAME_TEST = 'test.deepblue.lib.umich.edu'.freeze unless const_defined? :HOSTNAME_TEST
    HOSTNAME_TESTING = 'testing.deepblue.lib.umich.edu'.freeze unless const_defined? :HOSTNAME_TESTING
    HOSTNAME_STAGING = 'staging.deepblue.lib.umich.edu'.freeze unless const_defined? :STAGING

  end

end
