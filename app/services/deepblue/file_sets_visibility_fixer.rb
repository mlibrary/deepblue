# frozen_string_literal: true

module Deepblue

  class FileSetsVisibilityFixer < AbstractFixer

    mattr_accessor :file_sets_visibility_fixer_debug_verbose,
                   default: FindAndFixService.file_sets_visibility_fixer_debug_verbose

    PREFIX = 'FileSet visibility: '

    def self.fix( curation_concern:, msg_handler: nil )
      msg_handler ||= MessageHandler.msg_handler_for_task
      fixer = FileSetsVisibilityFixer.new( msg_handler: msg_handler )
      fixer.fix( curation_concern: curation_concern ) if fixer.fix_include?( curation_concern: curation_concern )
    end

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      super( filter: filter, msg_handler: msg_handler, prefix: PREFIX )
    end

    def debug_verbose
      file_sets_visibility_fixer_debug_verbose && msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      return false unless curation_concern.parent.present?
      return super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      parent = curation_concern.parent
      if curation_concern.visibility != parent.visibility
        curation_concern.visibility = parent.visibility
        curation_concern.date_modified = DateTime.now
        curation_concern.save!( validate: false )
        add_id_fixed curation_concern.id
        msg_verbose "FileSet #{curation_concern.id} parent work #{parent.id} updating visibility."
      end
    end

  end

end
