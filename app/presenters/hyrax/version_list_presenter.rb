# frozen_string_literal: true
# Reviewed: hyrax4

# monkey override

module Hyrax

  class VersionListPresenter

    mattr_accessor :version_list_presenter_debug_verbose,
                   default: Rails.configuration.version_list_presenter_debug_verbose

    ##
    # @param version_list [Array<#created>]
    def initialize(version_list)
      @raw_list = version_list
    end

    ##
    # @param [Object] an object representing the File Set
    #
    # @return [Enumerable<Hyrax::VersionPresenter>] an enumerable of presenters
    #   for the relevant file versions.
    #
    # @raise [ArgumentError] if we can't build an enu
    def self.for(file_set:)
      original_file = if file_set.respond_to?(:original_file)
                        file_set.original_file
                      else
                        Hyrax::FileSetFileService.new(file_set: file_set).original_file
                      end
      new(Hyrax::VersioningService.new(resource: original_file).versions)
    rescue NoMethodError
      raise ArgumentError
    end

    delegate :each, to: :wrapped_list

    def debug_verbose
      VersionListPresenter.version_list_presenter_debug_verbose
    end

    def view_debug_verbose
      VersionListPresenter.version_list_presenter_debug_verbose
    end

    def size
      @raw_list.size
    end

    def to_a
      arr = wrapped_list
      return arr
    end

    private

      def wrapped_list
        @wrapped_list ||=
          @raw_list.map { |v| Hyrax::VersionPresenter.new(v) } # wrap each item in a presenter
                   .sort { |a, b| b.version.created <=> a.version.created } # sort list of versions based on creation date
                   .tap { |l| l.first.try(:current!) } # set the first version to the current version
      end

  end

end
