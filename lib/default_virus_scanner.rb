# frozen_string_literal: true

class DefaultVirusScanner < Hydra::Works::VirusScanner

  def initialize( file )
    super( file )
  end

  def can_scan?( original_file )
    return false unless defined? ClamAV
    return false unless original_file && original_file.new_record? # We have a new file to check
    return false unless original_file.size <= DeepBlueDocs::Application.config.virus_scan_max_file_size
    return true
  end

end
