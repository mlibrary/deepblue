# frozen_string_literal: true

module Deepblue

  class TaskPacifier

    attr_accessor :active, :count_nl

    attr_reader :count, :out

    def initialize( out: $stdout, count_nl: 100 )
      @out = out
      @count = 0
      @count_nl = count_nl
      @active = true
    end

    def active?
      @active
    end

    def pacify( x = '.' )
      return unless active
      x = x.to_s
      @count = @count + x.length
      @out.print x
      if @count > @count_nl
        nl
      end
      @out.flush
    end

    def pacify_bracket( x, bracket_open: '(', bracket_close: ')' )
      return unless active
      x = x.to_s
      x = "#{bracket_open}#{x}#{bracket_close}" if x.length > 1
      pacify x
    end

    def nl
      return unless active
      @out.print "\n"
      @out.flush
      @count = 0
    end

    def reset
      return unless active
      @count = 0
    end

  end

end
