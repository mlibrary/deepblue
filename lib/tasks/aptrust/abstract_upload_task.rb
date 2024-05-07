# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../../app/services/aptrust/aptrust_upload_work'
require_relative '../../../app/services/aptrust/aptrust_uploader'
require_relative '../../../app/services/aptrust/aptrust_uploader_for_work'

module Aptrust

  class AbstractUploadTask < ::Aptrust::AbstractTask

    attr_accessor :bag_max_total_file_size
    attr_accessor :cleanup_after_deposit
    attr_accessor :cleanup_bag
    attr_accessor :cleanup_bag_data
    attr_accessor :debug_assume_upload_succeeds
    attr_accessor :event_start # TODO (if event hasn't occurred, skip)
    attr_accessor :event_stop # TODO
    attr_accessor :max_size
    attr_accessor :max_upload_total_size
    attr_accessor :max_uploads
    attr_accessor :min_size
    attr_accessor :noid_pairs
    attr_accessor :sleep_secs
    attr_accessor :sort
    attr_accessor :zip_data_dir

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @bag_max_total_file_size = option_integer( key: 'bag_max_total_file_size' )
      @cleanup_after_deposit = option_value( key: 'cleanup_after_deposit', default_value: true )
      @cleanup_bag = option_value( key: 'cleanup_bag', default_value: true )
      @cleanup_bag_data = option_value( key: 'cleanup_bag_data', default_value: true )
      @debug_assume_upload_succeeds = option_value( key: 'debug_assume_upload_succeeds', default_value: false )
      @event_start = option_value( key: 'event_start' )
      @event_stop = option_value( key: 'event_stop' )
      @max_size = option_integer( key: 'max_size', default_value: -1 )
      @min_size = option_integer( key: 'min_size', default_value: -1 )
      @max_upload_total_size = option_integer( key: 'max_upload_total_size', default_value: -1 )
      @max_uploads = option_max_uploads
      @sleep_secs = option_sleep_secs
      @sort = option_value( key: 'sort', default_value: false )
      @zip_data_dir = option_value( key: 'zip_data_dir', default_value: false )
    end

    def noid_pairs
      @noid_pairs ||= noid_pairs_init
    end

    def noid_pairs_init
      noids_sort
    end

    def noids_sort
      msg_handler.msg_verbose "Sorting noids into noid_pairs"
      @noid_pairs=[]
      return unless sort?
      return unless noids.present?
      w = WorkCache.new
      noids.each { |noid| w.reset.noid = noid; @noid_pairs << { noid: noid, size: w.total_file_size } }
      @noid_pairs.sort! { |a,b| a[:size] < b[:size] ? 0 : 1 }
      # @noid_pairs = @noid_pairs.select { |p| p[:size] <= max_size } if 0 < max_size
    end

    def option_max_size
      opt = task_options_value( key: 'max_size', default_value: -1 )
      opt = opt.strip if opt.is_a? String
      # opt = opt.to_i if opt.is_a? String
      opt = to_integer( num: opt ) if opt.is_a? String
      msg_handler.msg_verbose "max_size='#{opt}'"
      return opt
    end

    def option_max_uploads
      opt = task_options_value( key: 'max_uploads', default_value: -1 )
      opt = opt.strip if opt.is_a? String
      opt = opt.to_i if opt.is_a? String
      msg_handler.msg_verbose "max_uploads='#{opt}'"
      return opt
    end

    def option_sleep_secs
      opt = task_options_value( key: 'sleep_secs', default_value: -1 )
      opt = opt.strip if opt.is_a? String
      opt = opt.to_i if opt.is_a? String
      msg_handler.msg_verbose "sleep_secs=#{opt}"
      return opt
    end

    def run_noids_upload
      total_size = 0
      w = WorkCache.new
      noids.each do |noid|
        w.reset.noid = noid
        size = w.total_file_size
        next if max_upload_total_size > 0 && total_size + size > max_upload_total_size
        run_upload( noid: noid )
        total_size += size
      end
    end

    def filter_in_pair_by_size( pair )
      max_sz = max_size
      min_sz = min_size
      return true if max_sz <= 0 && min_sz <= 0
      return pair[:size] <= max_sz if max_sz > 0 && min_sz <= 0
      return min_sz <= pair[:size] if min_sz > 0 && max_sz <= 0
      return min_sz <= pair[:size] && pair[:size] <= max_sz
    end

    def filter_in_pair_by_size_msg
      max_sz = max_size
      min_sz = min_size
      return '' if max_sz <= 0 && min_sz <= 0
      return "size <= #{readable_sz( max_sz )}" if max_sz > 0 && min_sz <= 0
      return "#{readable_sz( min_sz )} <= size" if min_sz > 0 && max_sz <= 0
      return "#{readable_sz( min_sz )} <= size <= #{readable_sz( max_sz )}"
    end

    def run_pair_uploads
      unless noid_pairs.present?
        msg_handler.msg_verbose "No NOIDs found for date begin: '#{options['date_begin']}' and date end: '#{options['date_end']}'"
        return
      end
      if max_size > 0 || min_size > 0
        msg_handler.msg_verbose "Select noids with #{filter_in_pair_by_size_msg}"
        @noid_pairs = @noid_pairs.select { |pair| filter_in_pair_by_size( pair ) }
      end
      if max_uploads > 0
        msg_handler.msg_verbose "Limit uploads to #{max_uploads} at most."
        @noid_pairs = @noid_pairs[0..(max_uploads-1)] if @noid_pairs.size > max_uploads
      end
      total_size = 0
      @noid_pairs.each_with_index do |pair,index|
        size = pair[:size]
        total_size += size
        msg_handler.msg_verbose "#{index}: #{pair[:noid]} -- #{readable_sz( size )}"
      end if verbose
      msg_handler.msg_verbose "Total upload size: #{readable_sz( total_size )}"
      msg_handler.msg_verbose "test_mode?=#{test_mode?}"
      return if test_mode?
      total_size = 0
      @noid_pairs.each do |pair|
        size = pair[:size]
        next if max_upload_total_size > 0 && total_size + size > max_upload_total_size
        run_upload( noid: pair[:noid], size: size )
        total_size += size
      end
    end

    def run_upload( noid:, size: nil )
      msg_handler.msg_verbose "sleeping for #{sleep_secs}" if 0 < sleep_secs
      sleep( sleep_secs ) if 0 < sleep_secs
      msg = "Uploading: #{noid}"
      msg += " - #{readable_sz(size)}" if size.present?
      msg_handler.msg_verbose msg
      ::Aptrust::AptrustIntegrationService.dump_mattrs.each { |a| msg_handler.msg_verbose a } if debug_verbose
      msg_handler = ::Deepblue::MessageHandler.msg_handler_for( task: true,
                                                                verbose: verbose,
                                                                debug_verbose: debug_verbose )
      uploader = uploader_for( noid: noid )
      @export_dir = File.absolute_path @export_dir if @export_dir.present?
      @working_dir = File.absolute_path @working_dir if @working_dir.present?
      uploader.export_dir = @export_dir if @export_dir.present?
      uploader.working_dir = @working_dir if @working_dir.present?

      # msg_handler.msg_verbose "uploader=#{uploader.pretty_inspect}"
      msg_handler.msg_verbose "test_mode?=#{test_mode?}"
      return if test_mode?
      uploader.run
    end

    def sort?
      @sort
    end

    def uploader_for( noid: )
      uploader = ::Aptrust::AptrustUploadWork.new( msg_handler: msg_handler, debug_verbose: debug_verbose,
                                                   bag_max_total_file_size: bag_max_total_file_size,
                                                   cleanup_after_deposit: cleanup_after_deposit,
                                                   cleanup_bag: cleanup_bag,
                                                   cleanup_bag_data: cleanup_bag_data,
                                                   debug_assume_upload_succeeds: debug_assume_upload_succeeds,
                                                   event_start: event_start,
                                                   event_stop: event_stop,
                                                   noid: noid,
                                                   zip_data_dir: zip_data_dir )
      return uploader
    end

  end

end
