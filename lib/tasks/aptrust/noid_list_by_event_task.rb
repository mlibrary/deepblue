# frozen_string_literal: true

require_relative './abstract_task'

module Aptrust

  class NoidListByEventTask < ::Aptrust::AbstractTask

    attr_accessor :event
    attr_accessor :max_size
    attr_accessor :ruby_list
    attr_accessor :sort

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
    end

    def event
      @event ||= option_event
    end

    def max_size
      @max_size ||= option_max_size
    end

    def option_event
      opt = task_options_value( key: 'event', default_value: ::Aptrust::EVENT_FAILED )
      opt.strip! if opt.is_a? String
      msg_handler.msg_verbose "event='#{opt}'" if verbose
      return opt
    end

    def option_max_size
      opt = task_options_value( key: 'max_size', default_value: -1 )
      opt.strip! if opt.is_a? String
      opt = opt.to_i if opt.is_a? String
      msg_handler.msg_verbose "max_size='#{opt}'" if verbose
      return opt
    end

    def ruby_list
      @ruby_list ||= option_value( key: 'ruby_list', default_value: false )
    end

    def run
      msg_handler.msg_verbose "Starting..."
      ids = run_find_ids
      run_list( ids: ids )
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'Aptrust::NoidListByEventTask', event: 'NoidListByEventTask' )
    end

    def run_find_ids
      ids=[]
      ::Aptrust::Status.all.each do |status|
        next if status.event == ::Aptrust::EVENT_DELETED
        ids << status.noid if event == status.event
      end
      return ids if 0 > max_size && !sort?
      id_pairs=[]
      ids.each { |id| w = DataSet.find id; id_pairs << { id: id, size: w.total_file_size } }
      id_pairs.sort! { |a,b| a[:size] < b[:size] ? 0 : 1 }
      id_pairs = id_pairs.select { |p| p[:size] <= max_size } if 0 < max_size
      return id_pairs
    end

    def run_list( ids: )
      if ruby_list
        msg_handler.msg "%w[#{ids.join(' ')}]"
      else
        msg_handler.msg "ids.size=#{ids.size}"
        return if ids.empty?
        first = ids.first
        if first.is_a? String
          ids.each { |id| msg_handler.msg "#{id}"}
        else
          ids.each_with_index do |pair,index|
            msg_handler.msg "#{index}: #{pair[:id]}: #{readable_sz(pair[:size])}"
          end
        end
      end
    end

    def sort
      @sort ||= option_value( key: 'sort', default_value: false )
    end

  end

end
