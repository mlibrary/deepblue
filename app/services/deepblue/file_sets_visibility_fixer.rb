# frozen_string_literal: true

module Deepblue

  class FileSetsVisibilityFixer < ::Deepblue::AbstractFixer

    mattr_accessor :file_sets_visibility_fixer_debug_verbose,
                   default: ::Deepblue::FindAndFixService.file_sets_visibility_fixer_debug_verbose

    PREFIX = 'FileSet visibility: '

    def initialize( debug_verbose: file_sets_visibility_fixer_debug_verbose,
                    filter: Deepblue::FindAndFixService.find_and_fix_default_filter,
                    task: false,
                    verbose: Deepblue::FindAndFixService.find_and_fix_default_verbose )

      super( filter: filter,
             prefix: PREFIX,
             verbose: verbose,
             debug_verbose: debug_verbose,
             task: task )
    end

    def fix_include?( curation_concern:, messages: )
      return false unless curation_concern.parent.present?
      return super( curation_concern: curation_concern, messages: messages )
    end

    def fix( curation_concern:, messages: )
      parent = curation_concern.parent
      if curation_concern.visibility != parent.visibility
        curation_concern.visibility = parent.visibility
        curation_concern.date_modified = DateTime.now
        curation_concern.save!( validate: false )
        ids_fixed << curation_concern.id
        add_msg messages, "FileSet #{curation_concern.id} parent work #{parent.id} updating visibility." if verbose
      end
    end

  end

end
