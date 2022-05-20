# frozen_string_literal: true

class UglifierLogger < Logger

  def format_message( _severity, _timestamp, _progname, msg )
    "#{msg}\n"
  end

end

logfile = File.open( Rails.root.join( 'log', "uglifier_#{Rails.env}.log" ), 'a' ) # create log file
logfile.sync = true # automatically flushes data to file
UGLIFIER_LOGGER = UglifierLogger.new( logfile ) # constant accessible anywhere

class UglifierProxy

  mattr_accessor :uglifier_proxy_debug_verbose, default: false
  mattr_accessor :uglifier_proxy_echo_error_to_stdout, default: false

  instance_methods.each do |m|
    undef_method(m) unless m =~ /(^__|^nil\?|^send$|^object_id$)/
  end

  # Minifies JavaScript code using implicit context.
  #
  # @param source [IO, String] valid JS source code.
  # @param options [Hash] optional overrides to +Uglifier::DEFAULTS+
  # @return [String] minified code.
  def self.compile(source, options = {})
    @@logger = Rails.logger
    @@logger ||= UGLIFIER_LOGGER
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ],
                                         logger: @@logger if UglifierProxy.uglifier_proxy_debug_verbose
    Uglifier.new(options)
    new(options).compile(source)
  end

  # Minifies JavaScript code and generates a source map using implicit context.
  #
  # @param source [IO, String] valid JS source code.
  # @param options [Hash] optional overrides to +Uglifier::DEFAULTS+
  # @return [Array(String, String)] minified code and source map.
  def self.compile_with_map(source, options = {})
    @@logger = Rails.logger
    @@logger ||= UGLIFIER_LOGGER
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ],
                                         logger: @@logger if UglifierProxy.uglifier_proxy_debug_verbose
    Uglifier.new(options)
    new(options).compile_with_map(source)
  end

  def initialize(options = {})
    @@logger = Rails.logger
    @@logger ||= UGLIFIER_LOGGER
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "" ],
                                         logger: @@logger if UglifierProxy.uglifier_proxy_debug_verbose
    @options = options
    @uglifier = Uglifier.new(options)
  end

  # Minifies JavaScript code
  #
  # @param source [IO, String] valid JS source code.
  # @return [String] minified code.
  def compile(source)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ],
                                         logger: @@logger if UglifierProxy.uglifier_proxy_debug_verbose
    begin
      @uglifier.compile(source)
    rescue Exception => e
      ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                             "#{e.class}: #{e.message} at #{e.backtrace[0]}",
                                             "" ] + e.backtrace,
                                           bold_puts: UglifierProxy.uglifier_proxy_echo_error_to_stdout,
                                           logger: UGLIFIER_LOGGER
      # if @options[:source_map]
      #   compiled, source_map = run_uglifyjs(source, true)
      #   source_map_uri = Base64.strict_encode64(source_map)
      #   source_map_mime = "application/json;charset=utf-8;base64"
      #   compiled + "\n//# sourceMappingURL=data:#{source_map_mime},#{source_map_uri}"
      # else
      #   run_uglifyjs(source, false)
      # end
      source # return the source
    end
  end
  alias_method :compress, :compile

  private

  def method_missing( method, *args, &block )
    @uglifier.send(method, *args, &block)
  end

end
