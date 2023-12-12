# frozen_string_literal: true

module Deepblue

  class FindCurationConcernFilterSize < AbstractFindCurationConcern

    attr_accessor :max_size
    attr_accessor :min_size

    def initialize( min_size:, max_size: )
      super
      @max_size = max_size
      @min_size = min_size
    end

    def include?( cc_size )
      return false if cc_size.nil?
      return false if cc_size < min_size
      return false if cc_size > max_size
      return true
    end

  end

end
