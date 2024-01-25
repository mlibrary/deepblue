# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustVerifier

  mattr_accessor :aptrust_verifier_debug_verbose, default: false

  attr_accessor :aptrust_config
  attr_accessor :aptrust_config_file
  attr_accessor :aptrust_upload_status

  attr_accessor :debug_assume_verify_succeeds

  attr_accessor :msg_handler

  attr_accessor :object_id

  attr_accessor :debug_verbose

  def initialize( object_id:,
                  msg_handler:         nil,

                  aptrust_config:      nil,
                  aptrust_config_file: nil, # ignored if aptrust_config is defined

                  debug_assume_verify_succeeds: false,

                  debug_verbose:       aptrust_verifier_debug_verbose )

    @debug_verbose = debug_verbose
    @debug_verbose ||= aptrust_verifier_debug_verbose
    @msg_handler = msg_handler
    @msg_handler ||= ::Aptrust::NULL_MSG_HANDLER

    @object_id           = object_id

    @aptrust_config      = aptrust_config
    @aptrust_config_file = aptrust_config_file
    @aptrust_config      ||= aptrust_config_init

    @debug_assume_verify_succeeds = debug_assume_verify_succeeds
  end

  def aptrust_config_init
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if debug_verbose
    if @aptrust_config.blank?
      @aptrust_config = if @aptrust_config_file.present?
                          ::Aptrust::AptrustConfig.new( filename: @aptrust_config_filename )
                        else
                          ::Aptrust::AptrustConfig.new
                        end
    end
    @aptrust_config
  end

  def aptrust_upload_status
    @aptrust_uploader_status ||= ::Aptrust::AptrustUploaderStatus.new( id: @object_id )
  end

  def track( status:, note: nil )
    aptrust_upload_status.track( status: status, note: note )
  end

end
