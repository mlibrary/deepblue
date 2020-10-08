# frozen_string_literal: true

module Deepblue

  module SystemMonitorHelper

    #
    # serialize a normal array of values to an array of ordered values
    #
    def self.space( dir: '.' )
      rv = `df -H #{dir}`
      lines = rv.split( "\n" )
      arrs = lines.map { |line| line.split(/\s+/) }
      arrs = arrs.map { |arr| arr.slice( 1, 4 ) }
      rows = arrs.map { |arr| "<tr><td>#{arr.join("</td><td>")}</td></tr>" }
      "<table>\n#{rows.join("\n")}\n</table>"
    end

    def self.space_dbd
      self.space( dir: '.' )
    end

    def self.space_globus
      return "N/A" unless ::Deepblue::GlobusIntegrationService.globus_enabled
      return "N/A" unless Dir.exist? ::Deepblue::GlobusIntegrationService.globus_dir
      space( dir: ::Deepblue::GlobusIntegrationService.globus_dir )
    end

    def self.space_prep
      return "N/A" unless Dir.exist? ::Deepblue::IngestIntegrationService.deepbluedata_prep
      space( dir: ::Deepblue::IngestIntegrationService.deepbluedata_prep )
    end

  end

end
