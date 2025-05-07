# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../../app/services/file_sys_export_c'
require_relative '../../../app/services/data_den_export_service'

module DataDen

  class AbstractExportTask < ::DataDen::AbstractTask

    attr_accessor :event_start # TODO (if event hasn't occurred, skip)
    attr_accessor :event_stop # TODO
    attr_accessor :export_draft
    attr_accessor :force_export
    attr_accessor :max_size
    attr_accessor :max_export_total_size
    attr_accessor :max_exports
    attr_accessor :min_size
    attr_accessor :noid_pairs
    attr_accessor :skip_export
    attr_accessor :sleep_secs
    attr_accessor :sort

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @event_start           = option_value( key: 'event_start' )
      @event_stop            = option_value( key: 'event_stop' )
      @export_draft          = option_value( key: 'export_draft', default_value: false )
      @force_export          = option_value( key: 'force_export', default_value: false )
      @max_size              = option_integer( key: 'max_size', default_value: -1 )
      @min_size              = option_integer( key: 'min_size', default_value: -1 )
      @max_export_total_size = option_integer( key: 'max_export_total_size', default_value: -1 )
      @max_exports           = option_max_exports
      @skip_export           = option_value( key: 'skip_export', default_value: false )
      @sleep_secs            = option_sleep_secs
      @sort                  = option_value( key: 'sort', default_value: false )
      @export_service = nil
    end

    def handled_missing_work?( fs_rec:, dsc: )
      return false if dsc.data_set_present?
      if FileSysExportIntegrationService.automatic_set_deleted_status
        if PersistHelper.gone_id? dsc.noid
          export_service.delete_work_logical( noid: dsc.noid )
          return true
        end
      end
      msg_handler.msg_warn "Failed to load work with noid: #{fs_rec.noid}"
      return true
    end

    def noid_pairs
      @noid_pairs ||= noid_pairs_init
    end

    def noid_pairs_init
      noids_sort
    end

    def noids_sort
      return unless sort?
      return unless noids.present?
      msg_handler.msg_verbose "Sorting noids into noid_pairs"
      @noid_pairs=[]
      dsc = DataSetCache.new
      noids.each do |noid|
        dsc.reset_with noid
        if !dsc.data_set_present?
          msg_handler.msg_warn "Failed to load data set with noid #{noid}"
          # TODO: try loading the work from fedora and saving to solr
          next
        end
        unless export_draft
          next if dsc.draft?
        end
        @noid_pairs << { noid: noid, size: dsc.total_file_size }
      end
      # puts @noid_pairs.pretty_inspect
      @noid_pairs.sort! { |a,b| a[:size] <=> b[:size] } if @noid_pairs.size > 1
      # @noid_pairs.sort! { |a,b| sort_pair( a, b ) } if @noid_pairs.size > 1
    end

    def sort_pair( a, b )
      a_size = a[:size]
      b_size = b[:size]
      a_size <=> b_size
    end

    def option_max_size
      opt = task_options_value( key: 'max_size', default_value: -1 )
      opt = opt.strip if opt.is_a? String
      # opt = opt.to_i if opt.is_a? String
      opt = to_integer( num: opt ) if opt.is_a? String
      msg_handler.msg_debug "max_size='#{opt}'" if debug_verbose
      return opt
    end

    def option_max_exports
      opt = task_options_value( key: 'max_exports', default_value: -1 )
      opt = opt.strip if opt.is_a? String
      opt = opt.to_i if opt.is_a? String
      msg_handler.msg_debug "max_exports='#{opt}'" if debug_verbose
      return opt
    end

    def option_sleep_secs
      opt = task_options_value( key: 'sleep_secs', default_value: -1 )
      opt = opt.strip if opt.is_a? String
      opt = opt.to_i if opt.is_a? String
      msg_handler.msg_debug "sleep_secs=#{opt}" if debug_verbose
      return opt
    end

    def run_noids_export
      total_size = 0
      dsc = DataSetCache.new
      noids.each do |noid|
        dsc.reset_with noid
        if !dsc.data_set_present?
          msg_handler.msg_warn "Failed to load data set with noid #{noid}"
          next
        end
        unless 0 < dsc.total_file_size
          # msg_handler.msg_warn "Total file size is zero for noid #{noid}"
          next
        end
        size = dsc.total_file_size
        next if max_export_total_size > 0 && total_size + size > max_export_total_size
        run_export( noid: noid )
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

    def run_pair_exports
      unless noid_pairs.present?
        begin_date = options['date_begin']
        end_date = options['date_end']
        if begin_date.present? && end_date.present?
          msg_handler.msg_verbose "No NOIDs found for date begin: '#{begin_date}' and date end: '#{end_date}'"
        elsif begin_date.present?
          msg_handler.msg_verbose "No NOIDs found with date begin: '#{begin_date}'"
        elsif end_date.present?
          msg_handler.msg_verbose "No NOIDs found with date end: '#{end_date}'"
        else
          msg_handler.msg_verbose "No NOIDs found."
        end
        return
      end
      if max_size > 0 || min_size > 0
        msg_handler.msg_verbose "Select noids with #{filter_in_pair_by_size_msg}"
        @noid_pairs = @noid_pairs.select { |pair| filter_in_pair_by_size( pair ) }
      end
      if max_exports > 0
        msg_handler.msg_verbose "Limit exports to #{max_exports} at most."
        @noid_pairs = @noid_pairs[0..(max_exports-1)] if @noid_pairs.size > max_exports
      end
      total_size = 0
      @noid_pairs.each_with_index do |pair,index|
        size = pair[:size]
        total_size += size
        msg_handler.msg_verbose "#{index}: #{pair[:noid]} -- #{readable_sz( size )}"
      end if verbose
      msg_handler.msg_verbose "Total export size: #{readable_sz( total_size )}"
      msg_handler.msg_verbose "Test mode: #{test_mode?}"
      return if test_mode?
      total_size = 0
      @noid_pairs.each do |pair|
        size = pair[:size]
        next if max_export_total_size > 0 && total_size + size > max_export_total_size
        run_export( noid: pair[:noid], size: size )
        total_size += size
      end
    end

    def run_export( noid:, size: nil )
      msg_handler.msg_verbose "sleeping for #{sleep_secs}" if 0 < sleep_secs
      sleep( sleep_secs ) if 0 < sleep_secs
      msg = "Exporting: #{noid}"
      msg += " - #{readable_sz(size)}" if size.present?
      msg_handler.msg_verbose msg
      msg_handler.msg_verbose "Test mode: #{test_mode?}"
      return if test_mode?
      export_service.export_data_set( noid: noid )
    end

    def run_reexport( noid:, size: nil )
      msg_handler.msg_verbose "sleeping for #{sleep_secs}" if 0 < sleep_secs
      sleep( sleep_secs ) if 0 < sleep_secs
      msg = "Exporting: #{noid}"
      msg += " - #{readable_sz(size)}" if size.present?
      msg_handler.msg_verbose msg
      msg_handler.msg_verbose "Test mode: #{test_mode?}"
      return if test_mode?
      export_service.reexport_data_set( noid: noid )
    end

    def sort?
      @sort
    end

    def export_service
      @export_service ||= DataDenExportService.new( msg_handler: msg_handler,
                                                    options: { force_export: force_export,
                                                               skip_export: skip_export,
                                                               test_mode: test_mode } )
      return @export_service
    end

  end

end
