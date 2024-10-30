# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../../app/services/aptrust/aptrust_find_and_verify'

module Aptrust

  class VerifyTask < ::Aptrust::AbstractTask

    attr_accessor :debug_assume_verify_succeeds
    attr_accessor :force_verification
    attr_accessor :reverify_failed
    attr_accessor :max_verifies

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      if msg_handler.nil?
        @verbose = true
        @msg_handler.verbose = @verbose
        @msg_handler.msg_queue = []
      else
        @verbose = @msg_handler.verbose
      end
      @debug_assume_verify_succeeds = task_options_value( key: 'debug_assume_verify_succeeds', default_value: false )
      @force_verification = task_options_value( key: 'force_verification', default_value: false )
      @reverify_failed = task_options_value( key: 'reverify_failed', default_value: false )
      @max_verifies = task_options_value( key: 'max_verifies', default_value: -1 )
      @email_subject = task_options_value( key: 'email_subject',
                                           default_value: "Aptrust verification on %hostname% finished %now%" ) if @email_subject.blank?
      @email_targets = option_email_targets( default_value: "fritx@umich.edu" ) if @email_targets.blank?
      @msg_handler.bold_debug [ @msg_handler.here, @msg_handler.called_from,
                               "debug_assume_verify_succeeds=#{debug_assume_verify_succeeds}",
                               "force_verification=#{force_verification}",
                               "reverify_failed=#{reverify_failed}",
                                "max_verifies=#{max_verifies}",
                                "test_mode=#{test_mode}",
                               "" ] if debug_verbose
      @msg_handler.msg_debug "debug_assume_verify_succeeds=#{debug_assume_verify_succeeds}"
      @msg_handler.msg_debug "force_verification=#{force_verification}"
      @msg_handler.msg_debug "reverify_failed=#{reverify_failed}"
      @msg_handler.msg_debug "max_verifies=#{max_verifies}"
      @msg_handler.msg_debug "test_mode=#{test_mode}"
    end

    def run
      debug_verbose
      msg_handler.msg_verbose
      msg_handler.msg_verbose "Started..."
      run_verify
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'Aptrust::VerifyTask', event: 'VerifyTask', debug_verbose: debug_verbose )
    end

    def run_verify
      verifier = ::Aptrust::AptrustFindAndVerify.new( debug_assume_verify_succeeds: debug_assume_verify_succeeds,
                                                      force_verification:           force_verification,
                                                      reverify_failed:              reverify_failed,
                                                      max_verifies:                 max_verifies,
                                                      test_mode:                    test_mode,
                                                      msg_handler:                  msg_handler,
                                                      debug_verbose:                debug_verbose )
      verifier.run
    end

  end

end
