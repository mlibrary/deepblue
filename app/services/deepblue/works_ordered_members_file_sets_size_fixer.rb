# frozen_string_literal: true

module Deepblue

  class WorksOrderedMembersFileSetsSizeFixer < AbstractFixer

    mattr_accessor :works_ordered_members_file_sets_size_fixer_debug_verbose,
                   default: FindAndFixService.works_ordered_members_file_sets_size_fixer_debug_verbose

    PREFIX = 'WorksOrderedMembers vs FileSets: '

    def initialize( debug_verbose: works_ordered_members_file_sets_size_fixer_debug_verbose,
                    filter: Deepblue::FindAndFixService.find_and_fix_default_filter,
                    task: false,
                    verbose: Deepblue::FindAndFixService.find_and_fix_default_verbose )

      super( debug_verbose: debug_verbose,
             filter: filter,
             prefix: PREFIX,
             task: task,
             verbose: verbose )
    end

    def fix_include?( curation_concern:, messages: )
      return false unless curation_concern.respond_to? :file_sets
      return super( curation_concern: curation_concern, messages: messages )
    end

    def fix( curation_concern:, messages: )
      ordered_members = Array( curation_concern.ordered_members )
      file_sets = curation_concern.file_sets
      if ordered_members.size != file_sets.size
        add_msg messages, "Mismatch with file_sets in work #{curation_concern.id}." if verbose
        curation_concern.ordered_members = file_sets
        curation_concern.save!( validate: false )
        @ids_fixed << curation_concern.id
      end
    end

  end

end
