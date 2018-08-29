# frozen_string_literal: true

module Hydra::Works

  module VirusCheck
    extend ActiveSupport::Concern

    # Move this to Ingest step
    # included do
    #   validate :must_not_detect_viruses
    #
    #   def must_not_detect_viruses
    #     scan_result = virus_scan
    #     return true unless virus_scan_detected_virus?( scan_result: scan_result )
    #     errors.add( :base, "Failed to verify uploaded file is not a virus" )
    #     false
    #   end
    #
    # end

  end

end
