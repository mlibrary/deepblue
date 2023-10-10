# frozen_string_literal: true

module Deepblue

  class FileSetsEmbargoFixer < AbstractFixer

    mattr_accessor :file_sets_embargo_fixer_debug_verbose,
                   default: FindAndFixService.file_sets_embargo_fixer_debug_verbose

    PREFIX = 'FileSet embargo: '

    def self.fix( curation_concern:, msg_handler: nil )
      msg_handler ||= MessageHandler.msg_handler_for_task
      fixer = FileSetsEmbargoFixer.new( msg_handler: msg_handler )
      fixer.fix( curation_concern: curation_concern ) if fixer.fix_include?( curation_concern: curation_concern )
    end

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      super( filter: filter, msg_handler: msg_handler, prefix: PREFIX )
    end

    def debug_verbose
      file_sets_embargo_fixer_debug_verbose && msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      return false unless curation_concern.parent.present?
      return false if curation_concern.ingesting?
      return super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      parent = curation_concern.parent
      if curation_concern.embargo.present? && parent.embargo.blank?
        curation_concern.embargo = nil
        # curation_concern.date_modified = DateTime.now
        # curation_concern.save!( validate: false )
        curation_concern.metadata_touch
        add_id_fixed curation_concern.id
        msg_verbose "FileSet #{curation_concern.id} parent work #{parent.id} updating embargo."
      elsif parent.embargo&embargo_release_date.present?
        apply_embargo( curation_concern )
        curation_concern.metadata_touch
        add_id_fixed curation_concern.id
        msg_verbose "FileSet #{curation_concern.id} parent work #{parent.id} updating embargo."
      end
    end

    def apply_embargo(curation_concern)
      parent = curation_concern.parent
      curation_concern.embargo_release_date = parent.embargo_release_date
      curation_concern.visibility_during_embargo = parent.visibility_during_embargo
      curation_concern.visibility_after_embargo = parent.visibility_after_embargo
    end

  end

end
