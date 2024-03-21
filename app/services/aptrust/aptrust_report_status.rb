# frozen_string_literal: true

require_relative './aptrust'

# TODO: fix this
class Aptrust::AptrustReportStatus < Aptrust::AbstractAptrustService

  mattr_accessor :aptrust_report_status_debug_verbose, default: false

  attr_accessor :target_file
  attr_accessor :csv
  attr_accessor :aws_bucket
  attr_accessor :column_names

  def initialize( msg_handler:         nil,
                  aptrust_config:      nil,
                  aptrust_config_file: nil, # ignored if aptrust_config is defined
                  target_file:         ,
                  debug_verbose:       aptrust_report_status_debug_verbose )

    super( msg_handler:         msg_handler,
           aptrust_config:      aptrust_config,
           aptrust_config_file: aptrust_config_file,
           debug_verbose:       debug_verbose )

    @target_file = target_file

    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "target_file=#{target_file}",
                             "" ] if debug_verbose
  end

  def column_names
    @column_names ||= [ "noid",
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
                       "updated_at"]
  end

  def csv
    @csv ||= csv_init
  end

  def csv_init
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "target_file=#{target_file}",
                             "" ] if debug_verbose
    rv = CSV.open( target_file, 'w', {:force_quotes=>true}  )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "rv=#{rv}",
                             "" ] if debug_verbose
    rv << column_names
    return rv
  end

  def aws_bucket
    @aws_bucket ||= aws_bucket_init
  end

  def aws_bucket_init
    bucket = ::Aptrust::AptrustAwsBucket.new( aptrust_config: aptrust_config )
    rv = bucket.files_from_local_repository
    return rv
  end

  def aws_bucket_contains( filename: )
    aws_bucket.include? filename
  end

  def aws_bucket_status( noid: )
    filename = "#{aptrust_config.identifier( noid: noid, type: 'DataSet' )}.tar"
    rv = aws_bucket_contains( filename: filename )
    return rv ? "in bucket" : ""
  end

  def process( status: )
    begin # until true for break
      noid = status.noid
      identifier = identifier( status: status )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "identifier=#{identifier}",
                               "noid=#{noid}",
                               "" ] if debug_verbose
      object_identifier = "object_identifier=#{aptrust_config.repository}\/#{identifier}"
      get_arg = "items?#{object_identifier}&action=Ingest"
      rv = get_response_body( get_arg: get_arg )
      success = rv[0]
      http_status = rv[1]
      body = rv[2]
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "success=#{success}",
                               "http_status=#{http_status}",
                               "body.pretty_inspect=#{body.pretty_inspect}",
                               "" ] if debug_verbose
      body ||= {}
      results = body["results"]
      results ||= []
      key_values = results.first
      key_values ||= {}
      row = []
      column_names.each do |col|
        if "noid" == col
          row << noid
        elsif "http_status" == col
          row << http_status
        elsif "aws_bucket_status" == col
          row << aws_bucket_status( noid: noid )
        else
          row << key_values[col]
        end
      end
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "row=#{row}",
                               "" ] if debug_verbose
      csv << row
    end until true # for break
  end

  def run
    begin # until true for break
      csv # force header
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "run", "" ] if debug_verbose
      ::Aptrust::Status.all.each do |status|
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "status.noid=#{status.noid}",
                                 "status.event=#{status.event}",
                                 "" ] if debug_verbose
        process( status: status )
      end
    rescue Exception => e
      Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
      msg_handler.bold_error [ msg_handler.here,
                               "Aptrust::AptrustReportStatus.run #{e.class}: #{e.message} at #{e.backtrace[0]}",
                               "" ] + e.backtrace # error
      raise
    end until true # for break
    csv.close unless @csv.nil?
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "run", "" ] if debug_verbose
  end

end
