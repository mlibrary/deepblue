# frozen_string_literal: true

module Deepblue

  class WorksFileSetsVisibilityFixer < AbstractFixer

    mattr_accessor :works_file_sets_visibility_fixer_debug_verbose,
                   default: FindAndFixService.works_file_sets_visibility_fixer_debug_verbose

    PREFIX = 'WorksFileSetsVisibilityFixer: '

    def self.fix( curation_concern:, msg_handler: nil )
      msg_handler ||= MessageHandler.msg_handler_for_task
      fixer = WorksFileSetsVisibilityFixer.new( msg_handler: msg_handler )
      fixer.fix( curation_concern: curation_concern ) if fixer.fix_include?( curation_concern: curation_concern )
    end

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      super( filter: filter, prefix: PREFIX, msg_handler: msg_handler )
    end

    def debug_verbose
      works_file_sets_visibility_fixer_debug_verbose || msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "curation_concern.id=#{curation_concern.id}",
      #                                        "" ] if debug_verbose
      return false unless curation_concern.respond_to? :file_sets
      super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "curation_concern.id=#{curation_concern.id}",
      #                                        "" ] if debug_verbose
      # msg_handler ||= @msg_handler
      fixed = false
      curation_concern.file_sets.each do |fs|
        if fs.visibility != curation_concern.visibility
          fs.visibility = curation_concern.visibility
          fs.save( validate: false )
          fixed = true
        end
      end
      add_id_fixed curation_concern.id if fixed
    end

  end

end
