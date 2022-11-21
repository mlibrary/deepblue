# frozen_string_literal: true

require 'abstract_virus_scanner'

class NullVirusScanner < AbstractVirusScanner

  mattr_accessor :null_virus_scanner_debug_verbose,
                 default: ::Deepblue::VirusScanService.null_virus_scanner_debug_verbose

  def initialize( filename )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "filename=#{filename}",
                                           "" ] if null_virus_scanner_debug_verbose
    super( filename )
  end

   def infected?
     ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if null_virus_scanner_debug_verbose
     super
   end

end
