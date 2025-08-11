# frozen_string_literal: true

module Deepblue

  class WorksOrderedMembersFileSetsSizeFixer < AbstractFixer

    mattr_accessor :works_ordered_members_file_sets_size_fixer_debug_verbose,
                   default: FindAndFixService.works_ordered_members_file_sets_size_fixer_debug_verbose

    PREFIX = 'WorksOrderedMembers vs FileSets: '

    def self.fix( curation_concern:, msg_handler: nil )
      msg_handler ||= MessageHandler.msg_handler_for_task
      fixer = WorksOrderedMembersFileSetsSizeFixer.new( msg_handler: msg_handler )
      fixer.fix( curation_concern: curation_concern ) if fixer.fix_include?( curation_concern: curation_concern )
    end

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      super( filter: filter, prefix: PREFIX, msg_handler: msg_handler )
    end

    def debug_verbose
      works_ordered_members_file_sets_size_fixer_debug_verbose || msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      return false unless curation_concern.respond_to? :file_sets
      return super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      ordered_members = Array( curation_concern.ordered_members )
      ordered_member_ids = Array( curation_concern.ordered_member_ids )
      file_sets = curation_concern.file_sets
      if ordered_members.size != file_sets.size || ordered_member_ids.size != file_sets.size
        msg_verbose "Ordered members mismatch with file_sets in work #{curation_concern.id}."
        curation_concern.ordered_members = file_sets
        curation_concern.save!( validate: false )
        @ids_fixed << curation_concern.id
      end
    end

  end

end

