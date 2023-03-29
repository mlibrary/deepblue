# frozen_string_literal: true

module Deepblue

  class FileSetsLostAndFoundFixer < AbstractFixer

    mattr_accessor :file_sets_lost_and_found_fixer_debug_verbose,
                   default: FindAndFixService.file_sets_lost_and_found_fixer_debug_verbose

    PREFIX = 'FileSet lost and found: '

    def self.fix( curation_concern:, msg_handler: nil )
      msg_handler ||= MessageHandler.msg_handler_for_task
      fixer = FileSetsLostAndFoundFixer.new( msg_handler: msg_handler )
      fixer.fix( curation_concern: curation_concern ) if fixer.fix_include?( curation_concern: curation_concern )
    end

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      super( msg_handler: msg_handler, filter: filter, prefix: PREFIX )
    end

    def debug_verbose
      file_sets_lost_and_found_fixer_debug_verbose && msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      return false unless curation_concern.parent.blank?
      return false if curation_concern.ingesting?
      return false unless lost_and_found_work.present?
      return super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      work = lost_and_found_work
      if work.is_a? DataSet
        msg_verbose "FileSet #{curation_concern.id} added to lost and found work #{work.id}"
        work.ordered_members << curation_concern
        work.save!( validate: false )
        work.reload
        add_id_fixed curation_concern.id
      else
        msg_verbose "FileSet #{curation_concern.id} has no parent. Create DataSet with title #{FindAndFixService.find_and_fix_file_sets_lost_and_found_work_title}"
      end
    end

    def lost_and_found_work
      @lost_and_found_work ||= init_lost_and_found_work
    end

    def init_lost_and_found_work
      FindAndFixService.lost_and_found_work
    end

  end

end
