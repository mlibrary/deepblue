# frozen_string_literal: true

require_relative './aptrust'
require_relative './aptrust_report_status'
require_relative './work_cache'

class Aptrust::AptrustFindAndVerify

  mattr_accessor :aptrust_find_and_verify_debug_verbose, default: false

  attr_accessor :debug_assume_verify_succeeds
  attr_accessor :debug_verbose
  attr_accessor :force_verification
  attr_accessor :max_verifies
  attr_accessor :msg_handler
  attr_accessor :reverify_failed
  attr_accessor :test_mode

  attr_accessor :count
  attr_accessor :count_warn
  attr_accessor :count_error
  attr_accessor :count_processing
  attr_accessor :count_verification_skipped
  attr_accessor :count_status_updated
  attr_accessor :status_counts
  attr_accessor :verification_counts
  attr_accessor :verify_count

  attr_accessor :verifier

  attr_accessor :aptrust_config

  def initialize( debug_assume_verify_succeeds: false,
                  force_verification:           false,
                  reverify_failed:              false,
                  max_verifies:                 -1,
                  test_mode:                    false,
                  msg_handler:                  nil,
                  debug_verbose:                aptrust_find_and_verify_debug_verbose )

    @debug_verbose = debug_verbose
    @debug_verbose ||= aptrust_find_and_verify_debug_verbose
    @msg_handler = msg_handler
    @msg_handler ||= ::Deepblue::MessageHandlerNull.new

    @test_mode = test_mode

    @debug_assume_verify_succeeds = debug_assume_verify_succeeds
    @force_verification = force_verification
    @reverify_failed = reverify_failed
    @max_verifies = max_verifies
    @verify_count = 0
    @aptrust_config = ::Aptrust::AptrustConfig.new

    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "debug_assume_verify_succeeds=#{debug_assume_verify_succeeds}",
                             "force_verification=#{force_verification}",
                             "max_verifies=#{max_verifies}",
                             "reverify_failed=#{reverify_failed}",
                             "test_mode=#{test_mode}",
                             # "@aptrust_config.pretty_inspect=#{@aptrust_config.pretty_inspect}",
                             "" ] if debug_verbose
  end

  def count_status( status )
    @status_counts ||= {}
    count = @status_counts[ status.event ]
    if count.nil?
      @status_counts[ status.event ] = 1
    end
    @status_counts[ status.event ] = @status_counts[ status.event ] + 1
  end

  def count_verification( status )
    status = status[:status] if status.is_a? Hash
    @verification_counts ||= {}
    count = @verification_counts[ status ]
    if count.nil?
      @verification_counts[ status ] = 1
    end
    @verification_counts[ status ] = @verification_counts[ status ] + 1
  end

  def identifier( status: )
    return aptrust_config.identifier( id_context: aptrust_config.context, noid: status.noid, type: "#{status.type}." )
  end

  def track_status
    return !@test_mode
  end

  def process( identifier:, noid:, status: )
    @verifier ||= ::Aptrust::AptrustStatusService.new( aptrust_config: aptrust_config,
                                                       force: true, # verification already done when called
                                                       # reverify_failed: reverify_failed,
                                                       track_status: track_status,
                                                       test_mode: test_mode,
                                                       msg_handler: msg_handler,
                                                       debug_assume_verify_succeeds: debug_assume_verify_succeeds,
                                                       debug_verbose: debug_verbose )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "identifier=#{identifier}",
                             "noid=#{noid}",
                             "status.event=#{status.event}",
                             "" ] if debug_verbose
    msg_handler.msg_debug [ "identifier=#{identifier}",
                            "noid=#{noid}",
                            "status.event=#{status.event}" ] if debug_verbose
    if status.event == ::Aptrust::EVENT_DEPOSIT_SKIPPED || debug_assume_verify_succeeds
      msg_handler.msg_debug "track status: #{::Aptrust::EVENT_VERIFY_SKIPPED}" if debug_verbose
      @verifier.object_id = noid
      @verifier.aptrust_upload_status = nil
      @verifier.track( status: ::Aptrust::EVENT_VERIFY_SKIPPED )
      rv = ::Aptrust::EVENT_VERIFY_SKIPPED
      @count_status_updated += 1
    else
      rv = @verifier.ingest_status( identifier: identifier, noid: noid )
      msg_handler.msg_debug [ "@verifier.ingest_status rv=#{rv}" ] if debug_verbose
    end
    @verify_count += 1
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "identifier=#{identifier}",
                             "noid=#{noid}",
                             "rv=#{rv}",
                             "" ] if debug_verbose
    return rv
  end

  def work_cache( noid: nil )
    @work_cache ||= ::Aptrust::WorkCache.new( msg_handler: msg_handler )
    @work_cache.reset
    @work_cache.noid = noid
    @work_cache
  end

  def needs_verification?( status: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             # "status=#{status.pretty_inspect}",
                             "noid=#{status.noid}",
                             "status.event=#{status.event}",
                             "" ] if debug_verbose
    msg_handler.msg_debug [ "force_verification=#{force_verification}" ] if debug_verbose
    return true if force_verification
    # msg_handler.msg_debug "status=#{status.pretty_inspect}"
    noid = status.noid
    msg_handler.msg_debug "noid=#{status.noid}"
    wc = work_cache( noid: noid )
    unless wc.work.present?
      msg_handler.msg_warn "Could not find work #{noid}"
      return false
    end
    total_file_size = wc.total_file_size
    msg_handler.msg_debug "total_file_size=#{DeepblueHelper.human_readable_size_str(total_file_size)}"
    delay_str = ""
    # set expected delay based on total size of work
    delay = if total_file_size > 500.gigabytes
              delay_str = "7 days"
              7.days
            elsif total_file_size > 100.gigabytes
              delay_str = "3 days"
              3.days
            elsif total_file_size > 1.gigabytes
              delay_str = "2 days"
              2.days
            else
              delay_str = "1 day"
              1.day
            end
    msg_handler.msg_debug "Delay based on total size of work is #{delay_str}."
    msg_handler.msg_debug "status.event=#{status.event}"
    #msg_handler.msg_debug "status.timestamp.class=#{status.timestamp.class}"
    msg_handler.msg_debug "status.timestamp=#{status.timestamp}"
    # x = ActiveSupport::TimeWithZone
    delta = Time.now - status.timestamp
    msg_handler.msg_debug "Older than #{delay_str}." if delta > delay
    return false unless delta > delay
    msg_handler.msg_debug [ "reverify_failed && ::Aptrust::EVENTS_FAILED.include?( status.event )=#{reverify_failed && ::Aptrust::EVENTS_FAILED.include?( status.event )}" ] if debug_verbose
    return true if reverify_failed && ::Aptrust::EVENTS_FAILED.include?( status.event )
    msg_handler.msg_debug [ "::Aptrust::EVENTS_NEED_VERIFY.include?( status.event )=#{::Aptrust::EVENTS_NEED_VERIFY.include?( status.event )}" ] if debug_verbose
    return true if ::Aptrust::EVENTS_NEED_VERIFY.include?( status.event )
    return false
  end

  def run
    @count = 0
    @count_warn = 0
    @count_error = 0
    @count_processing = 0
    @count_verification_skipped = 0
    @count_status_updated = 0
    begin
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
      msg_handler.msg_verbose "Find and verify starting loop in run..."
      ::Aptrust::Status.all.each do |status|
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "max_verifies=#{max_verifies}",
                                 "@verify_count=#{@verify_count}",
                                 "status.noid=#{status.noid}",
                                 "status.event=#{status.event}",
                                 "" ] if debug_verbose
        break if -1 != max_verifies && @verify_count >= max_verifies
        # next unless ::Aptrust::EVENTS_NEED_VERIFY.include? status.event
        if ::Aptrust::EVENTS_SKIPPED.include? status.event
          msg_handler.msg_warn "#{status.noid}: #{status.event}"
          @count_warn += 1
        end
        if ::Aptrust::EVENTS_ERRORS.include? status.event
          msg_handler.msg_error "#{status.noid}: #{status.event}"
          @count_error += 1
        end
        if ::Aptrust::EVENTS_PROCESSING.include? status.event
          msg_handler.msg "#{status.noid}: #{status.event}"
          @count_processing += 1
        end
        count_status( status )
        @count += 1
        unless needs_verification?( status: status )
          msg_handler.msg_debug "skipping #{status.noid} because needs_verification? is false" if debug_verbose
          @count_verification_skipped += 1
          next
        end
        msg_handler.msg_debug "process #{status.noid} because needs_verification?" if debug_verbose
        noid = status.noid
        identifier = identifier( status: status )
        rv = process( identifier: identifier, noid: noid, status: status )
        count_verification( status: rv )
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "rv=#{rv}",
                                 "" ] if debug_verbose
      end
      msg_handler.msg_verbose "Find and verify end of loop in run."
    rescue Exception => e
      Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
      msg_handler.msg_error "Aptrust::AptrustFindAndVerify.run #{e.class}: #{e.message} at #{e.backtrace[0]}"
      msg_handler.bold_error [ msg_handler.here,
                               "Aptrust::AptrustFindAndVerify.run #{e.class}: #{e.message} at #{e.backtrace[0]}",
                               "" ] + e.backtrace # error
      # raise
    end
    msg_handler.msg "Status warnings: #{@count_warn}" if @count_warn > 0 || debug_verbose
    msg_handler.msg "Status errors: #{@count_error}" if @count_error > 0 || debug_verbose
    msg_handler.msg "Status processing: #{@count_processing}" if @count_processing > 0 || debug_verbose
    msg_handler.msg "Status record count: #{@count}"
    msg_handler.msg "Verification skipped: #{@count_verification_skipped}" if @count_verification_skipped > 0 || debug_verbose
    msg_handler.msg "Verification updated: #{@count_status_updated}" if @count_status_updated > 0 || debug_verbose
    if msg_handler.verbose || debug_verbose
      msg_handler.msg "Status Counts:"
      @status_counts ||= {}
      @status_counts.each_pair do |status, count|
        msg_handler.msg "Status #{status}: #{count}"
      end
      msg_handler.msg "Verification Counts:"
      @verification_counts ||= {}
      @verification_counts.each_pair do |status, count|
        msg_handler.msg "Verification #{status}: #{count}"
      end
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "run", "" ] if debug_verbose
  end

end
