# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hydra-works").full_gem_path, "lib/hydra/works/services/virus_checker_services.rb" )

module Hydra::Works

  # monkey patch Hyrdra::Works::VirusCheckerService
  class VirusCheckerService
    alias_method :monkey_file_has_virus?, :file_has_virus?

    # Default behavior is to raise a validation error and halt the save if a virus is found
    def file_has_virus?
      if system_virus_scanner.respond_to? :can_scan?
        can_scan = system_virus_scanner.can_scan? original_file
        unless can_scan
          log_virus_scan_provenance( can_scan: false )
          return false
        end
      end
      has_virus = monkey_file_has_virus?
      # path = original_file.is_a?(String) ? original_file : local_path_for_file(original_file)
      # rv = system_virus_scanner.infected?(path)
      log_virus_scan_provenance( has_virus: has_virus )
      return rv
    end

    protected

      def log_virus_scan_provenance( can_scan: true, has_virus: false )
        # TODO: provenance logging
      end

  end

end
