# frozen_string_literal: true

module Deepblue

  class WorksOrderedMembersNilsFixer < AbstractFixer

    mattr_accessor :works_ordered_members_nils_fixer_debug_verbose,
                   default: FindAndFixService.works_ordered_members_nils_fixer_debug_verbose

    PREFIX = 'WorksOrderedMembers nils: '

    def initialize( debug_verbose: works_ordered_members_nils_fixer_debug_verbose,
                    filter: FindAndFixService.find_and_fix_default_filter,
                    task: false,
                    verbose: FindAndFixService.find_and_fix_default_verbose )

      super( debug_verbose: debug_verbose,
             filter: filter,
             prefix: PREFIX,
             task: task,
             verbose: verbose )
    end

    def fix_include?( curation_concern:, messages: )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "curation_concern.id=#{curation_concern.id}",
      #                                        "" ], bold_puts: task if works_ordered_members_nils_fixer_debug_verbose
      @msg_queue ||= messages
      super( curation_concern: curation_concern, messages: messages )
    end

    def fix( curation_concern:, messages: )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "curation_concern.id=#{curation_concern.id}",
      #                                        "" ], bold_puts: task if works_ordered_members_nils_fixer_debug_verbose
      @msg_queue ||= messages
      ordered_members = Array( curation_concern.ordered_members )
      if ordered_members.include? nil
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.id=#{curation_concern.id}",
                                               "" ], bold_puts: task if works_ordered_members_nils_fixer_debug_verbose
        add_msg "Compacting ordered_members for work #{curation_concern.id}." if verbose
        ordered_members.compact
        ordered_members = [] if ordered_members.nil?
        curation_concern.ordered_members = ordered_members
        curation_concern.save!( validate: false )
        add_id_fixed curation_concern.id
      end
    end

  end

end
