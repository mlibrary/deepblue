# frozen_string_literal: true

module Deepblue

  class FileSetsVisibilityFixer < AbstractFixer

    mattr_accessor :file_sets_visibility_fixer_debug_verbose,
                   default: FindAndFixService.file_sets_visibility_fixer_debug_verbose

    PREFIX = 'FileSet visibility: '

    def initialize( debug_verbose: file_sets_visibility_fixer_debug_verbose,
                    filter: FindAndFixService.find_and_fix_default_filter,
                    msg_handler:,
                    verbose: FindAndFixService.find_and_fix_default_verbose )

      super( filter: filter,
             msg_handler: msg_handler,
             prefix: PREFIX,
             verbose: verbose,
             debug_verbose: debug_verbose || file_sets_visibility_fixer_debug_verbose )
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
