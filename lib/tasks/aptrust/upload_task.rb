# frozen_string_literal: true

require_relative './abstract_upload_task'

module Aptrust

  class UploadTask < ::Aptrust::AbstractUploadTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      putsf "@options=#{@options.pretty_inspect}" if verbose
      @sort = true
      @max_size = option_max_size
      @max_uploads = option_max_uploads
    end

    def run
      debug_verbose
      putsf if verbose
      putsf "Started..." if verbose
      run_find
      noids_sort
      run_pair_uploads
      putsf "Finished." if verbose
    end

    def run_find
      @noids = []
      test_dates_init
      w = WorkCache.new
      w_all.each do |work|
        w.reset.work = work
        next unless w.file_set_ids.size > 0
        next unless w.published?
        # putsf "Filter w.date_modified=#{w.date_modified}"
        # putsf "Filter #{test_date_begin} < #{w.date_modified} < #{test_date_end} ?"
        # putsf "next unless #{test_date_begin} <= #{w.date_modified} = #{test_date_begin <= w.date_modified}"
        # putsf "next unless #{w.date_modified} <= #{test_date_end} = #{w.date_modified <= test_date_end}"
        next unless @test_date_begin <= w.date_modified
        next unless w.date_modified <= @test_date_end
        next unless ::Aptrust::Status.has_status?( cc: w )
        @noids << w.id
      end
    end

    def run_pair_uploads
      unless noid_pairs.present?
        putsf "No NOIDs found for date begin: '#{options['date_begin']}' and date end: '#{options['date_end']}'" if verbose
        return
      end
      if max_size > 0
        putsf "Select noids with size less than #{readable_sz( max_size )}" if verbose
        @noid_pairs = @noid_pairs.select { |pair| pair[:size] < max_size }
      end
      if  max_uploads > 0
        putsf "Limit uploads to #{max_uploads} at most.}" if verbose
        @noid_pairs = @noid_pairs[0..(max_uploads-1)] if @noid_pairs.size > max_uploads
      end
      total_size = 0
      @noid_pairs.each_with_index do |pair,index|
        size = pair[:size]
        total_size += size
        putsf "#{index}: #{pair[:noid]} -- #{readable_sz( size )}" if verbose
      end if verbose
      putsf "Total upload size: #{readable_sz( total_size )}" if verbose
      putsf "test_mode?=#{test_mode?}" if verbose
      @noid_pairs.each { |pair| run_upload( noid: pair[:noid], size: pair[:size] ) } unless test_mode?
    end

  end

end
