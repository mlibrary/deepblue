# frozen_string_literal: true

module Deepblue

  class MessageHandler

    attr_accessor :msg_prefix, :msg_queue, :task, :verbose

    def initialize( msg_prefix: '', msg_queue: [], task: false, verbose: false )
      @msg_prefix = msg_prefix
      @msg_queue = msg_queue
      @task = task
      @verbose = verbose
    end

    def join( sep = nil )
      return '' if @msg_queue.blank?
      return @msg_queue.join if sep.nil?
      return @msg_queue.join sep
    end

    def msg( msg )
      msg = "#{@msg_prefix}msg" if @msg_prefix.present?
      @msg_queue << msg unless @msg_queue.nil?
      puts msg if task
    end

    def msg_verbose( msg )
      msg msg if @verbose
    end

  end

end
