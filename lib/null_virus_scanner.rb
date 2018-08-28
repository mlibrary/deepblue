# frozen_string_literal: true

require 'abstract_virus_scanner'

class NullVirusScanner < AbstractVirusScanner

  def initialize( file )
    super( file )
  end

end
