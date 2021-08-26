module Hyrax

  class VersionPresenter

    mattr_accessor :version_presenter_debug_verbose, default: Rails.configuration.version_presenter_debug_verbose

    attr_reader :version, :current

    def initialize(version)
      @version = version
      @current = false
    end

    delegate :label, :uri, to: :version
    alias current? current

    def current!
      @current = true
    end

    def created
      @created ||= version.created.in_time_zone.to_formatted_s(:long_ordinal)
    end

    def committer
      vc = Hyrax::VersionCommitter.where(version_id: @version.uri)
      vc.empty? ? nil : vc.first.committer_login
    end

    def debug_verbose
      VersionPresenter.version_presenter_debug_verbose
    end

    def view_debug_verbose
      VersionPresenter.version_presenter_debug_verbose
    end

    def file_size_human_readable
      # version.file_size
      'FSHR'
    end

  end

end
