# frozen_string_literal: true

require 'delegate'

module Deepblue

  class OaiRecord < SimpleDelegator

    def initialize( document, local_prefix )
      super( document )
      @local_prefix = local_prefix.to_s
    end

    def id
      "#{@local_prefix}#{__getobj__.id}"
    end

  end

end
