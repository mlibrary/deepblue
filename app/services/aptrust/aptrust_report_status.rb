# frozen_string_literal: true

require_relative './aptrust'
require_relative './abstract_aptrust_service'

class Aptrust::AptrustReportStatus < Aptrust::AbstractAptrustService

  mattr_accessor :aptrust_report_status_debug_verbose, default: false

  attr_accessor :target_file
  attr_accessor :csv
  attr_accessor :aws_bucket
  attr_accessor :aws_bucket_error
  attr_accessor :aws_bucket_initialized
  attr_accessor :column_names
  attr_accessor :test_mode

  attr_accessor :count
  attr_accessor :count_warn
  attr_accessor :count_error
  attr_accessor :count_processing
  attr_accessor :status_counts

  def initialize( msg_handler:         nil,
                  aptrust_config:      nil,
                  aptrust_config_file: nil, # ignored if aptrust_config is defined
                  target_file:         ,
                  test_mode:           false,
                  debug_verbose:       aptrust_report_status_debug_verbose )

    super( msg_handler:         msg_handler,
           aptrust_config:      aptrust_config,
           aptrust_config_file: aptrust_config_file,
           track_status:        false,
           test_mode:           test_mode,
           debug_verbose:       debug_verbose )

    @column_names = nil
    @target_file = target_file
    @test_mode = test_mode
    @aws_bucket = nil
    @aws_bucket_initialized = false
    @aws_bucket_error = nil

    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "target_file=#{target_file}",
                             "test_mode=#{test_mode}" ] if debug_verbose
  end

  def column_names
    if @column_names.nil?
      @column_names = [ "noid",
                        "http_status",
                        "aws_bucket_status",
                        "id",
                        "name",
                        "etag",
                        "institution_id",
                        "institution_name",
                        "institution_identifier",
                        "intellectual_object_id",
                        "object_identifier",
                        "alt_identifier",
                        "bag_group_identifier",
                        "storage_option",
                        "bagit_profile_identifier",
                        "source_organization",
                        "internal_sender_identifier",
                        "generic_file_id",
                        "generic_file_identifier",
                        "bucket",
                        "user",
                        "note",
                        "action",
                        "stage",
                        "status",
                        "outcome",
                        "bag_date",
                        "date_processed",
                        "retry",
                        "node",
                        "pid",
                        "needs_admin_review",
                        "queued_at",
                        "size",
                        "stage_started_at",
                        "aptrust_approver",
                        "inst_approver",
                        "created_at",
                        "updated_at" ]
      @row_index_action   = @column_names.find_index( "action" )
      @row_index_bag_date = @column_names.find_index( "bag_date" )
      @row_index_date_processed = @column_names.find_index( "date_processed" )
      @row_index_name    = @column_names.find_index( "name" )
      @row_index_noid    = @column_names.find_index( "noid" )
      @row_index_note    = @column_names.find_index( "note" )
      @row_index_outcome = @column_names.find_index( "outcome" )
      @row_index_stage   = @column_names.find_index( "stage" )
      @row_index_status  = @column_names.find_index( "status" )
    end
    @column_names
  end

  def csv
    @csv ||= csv_init
  end

  def csv_init
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "target_file=#{target_file}" ] if debug_verbose
    # rv = CSV.open( target_file, 'w', {:force_quotes=>true}  )
    rv = CSV.new( File.open( target_file, 'w' ), force_quotes: true )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "rv=#{rv}" ] if debug_verbose
    rv << column_names
    return rv
  end

  def aws_bucket
    return @aws_bucket if @aws_bucket_initialized
    return @aws_bucket if @aws_bucket_error.present?
    @aws_bucket = aws_bucket_init
    return @aws_bucket
  end

  def aws_bucket_availabled?
    aws_bucket
    @aws_bucket_initialized && @aws_bucket_error.blank?
  end

  def aws_bucket_init
    rv = nil
    begin
      bucket = ::Aptrust::AptrustAwsBucket.new( aptrust_config: aptrust_config )
      rv = bucket.files_from_local_repository
    rescue Aws::S3::Errors::AccessDenied => e1
      msg_handler.bold_error [ msg_handler.here, msg_handler.called_from, "aws_bucket_init #{e1}" ]
      @aws_bucket_error = "Access Denied"
    rescue Exception => e
      msg_handler.bold_error [ msg_handler.here, msg_handler.called_from, "aws_bucket_init #{e}" ]
      @aws_bucket_error = "#{e}"
    end
    @aws_bucket_initialized = true
    return rv
  end

  def aws_bucket_contains( filename: )
    return false unless aws_bucket_availabled?
    aws_bucket.include? filename
  end

  def aws_bucket_status( noid: )
    filename = "#{aptrust_config.identifier( noid: noid, type: 'DataSet' )}.tar"
    rv = aws_bucket_contains( filename: filename )
    return rv ? "in bucket" : ""
  end

  def count_status( status )
    @status_counts ||= {}
    count = @status_counts[ status.event ]
    if count.nil?
      @status_counts[ status.event ] = 1
    end
    @status_counts[ status.event ] = @status_counts[ status.event ] + 1
  end

  def get_record_from_aptrust( status: )
    noid = status.noid
    identifier = identifier( status: status )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "identifier=#{identifier}",
                             "noid=#{noid}",
                             "" ] if debug_verbose
    object_identifier = "object_identifier=#{aptrust_config.repository}\/#{identifier}"
    get_arg = "items?#{object_identifier}&action=Ingest"
    http_status = nil
    unless test_mode
      rv = get_response_body( get_arg: get_arg )
      success = rv[0]
      http_status ||= rv[1]
      body = rv[2]
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "success=#{success}",
                               "http_status=#{http_status}",
                               "body.pretty_inspect=#{body.pretty_inspect}",
                               "" ] if debug_verbose
      body ||= {}
      results = body["results"]
    end
    results ||= []
    key_values = results.first
    key_values ||= {}
    key_values["noid"] = noid
    key_values["http_status"] = http_status
    key_values["aws_bucket_status"] = aws_bucket_status( noid: noid ) unless test_mode
    return key_values
  end

  def run
    @count = 0
    @count_warn = 0
    @count_error = 0
    @count_processing = 0
    begin # until true for break
      csv # force header
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "run", "" ] if debug_verbose
      ::Aptrust::Status.all.each do |status|
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "status.noid=#{status.noid}",
                                 "status.event=#{status.event}",
                                 "" ] if debug_verbose
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
        row = row_read_from_aptrust( status: status )
        row_msg = row_status_msg( row: row )
        msg_handler.msg_warn row_msg if row_msg.present?
        row_write( row: row )
        count_status( status )
        @count += 1
      end
    rescue Exception => e
      Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
      msg_handler.bold_error [ msg_handler.here, msg_handler.called_from,
                               "Aptrust::AptrustReportStatus.run #{e.class}: #{e.message} at #{e.backtrace[0]}",
                               "" ] + e.backtrace # error
      raise
    end until true # for break
    csv.close unless @csv.nil?
    msg_handler.msg "Status warnings: #{@count_warn}" if @count_warn > 0
    msg_handler.msg "Status errors: #{@count_error}" if @count_error > 0
    msg_handler.msg "Status processing: #{@count_processing}" if @count_processing > 0
    msg_handler.msg "Status record count: #{@count}"
    if msg_handler.verbose
      @status_counts ||= {}
      @status_counts.each_pair do |status, count|
        msg_handler.msg_verbose "#{status}: #{count}"
      end
    end
    msg_handler.msg "Report written to: #{target_file}"
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "run", "" ] if debug_verbose
  end

  def row_read_from_aptrust( status: )
    # begin # until true for break
    key_values = get_record_from_aptrust( status: status )
    row = []
    column_names.each do |name|
      value = key_values[name]
      value ||= ""
      row << value
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "row=#{row}" ] if debug_verbose
    # end until true # for break
    return row
  end

  def row_status_msg( row: )
    return "" unless row.present?
    # "name"=>"deepbluedata.localhost-DataSet.f4752g73w.tar",
    # "note"=>"Finished cleanup. Ingest complete.",
    # "action"=>"Ingest",
    # "stage"=>"Cleanup",
    # "status"=>"Success",
    # "outcome"=>"Ingest complete",
    # "bag_date"=>"2024-03-13T13:43:00Z",
    # "date_processed"=>"2024-03-13T13:43:19.33718Z",
    action   = row[@row_index_action]
    bag_date = row[@row_index_bag_date]
    date_processed = row[@row_index_date_processed]
    name     = row[@row_index_name]
    noid     = row[@row_index_noid]
    note     = row[@row_index_note]
    outcome  = row[@row_index_outcome]
    stage    = row[@row_index_stage]
    status   = row[@row_index_status]
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "action=#{action}",
                             "bag_date=#{bag_date}",
                             "date_processed=#{date_processed}",
                             "name=#{name}",
                             "note=#{note}",
                             "outcome=#{outcome}",
                             "stage=#{stage}",
                             "status=#{status}",
                             "" ] if debug_verbose
    unless outcome == "Ingest complete"
      return "APTrust status for #{noid} / #{name}: #{action} at #{stage} as of #{date_processed} has outcome #{outcome}, #{note}"
    end
    return ""
  end

  def row_write( row: )
    csv << row
  end

end
