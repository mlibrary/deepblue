# frozen_string_literal: true

module Deepblue

  class WorksOrderedMembersNilsFixer < AbstractFixer

    mattr_accessor :works_ordered_members_nils_fixer_debug_verbose,
                   default: FindAndFixService.works_ordered_members_nils_fixer_debug_verbose

    PREFIX = 'WorksOrderedMembers nils: '

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      super( filter: filter, prefix: PREFIX, msg_handler: msg_handler )
    end

    def debug_verbose
      works_ordered_members_nils_fixer_debug_verbose && msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "curation_concern.id=#{curation_concern.id}",
      #                                        "" ] if debug_verbose
      super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "curation_concern.id=#{curation_concern.id}",
      #                                        "" ] if debug_verbose
      msg_handler ||= @msg_handler
      ordered_members = Array( curation_concern.ordered_members )
      if ordered_members.include? nil
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.id=#{curation_concern.id}",
                                               "" ] if debug_verbose
        msg_verbose "Compacting ordered_members for work #{curation_concern.id}."
        ordered_members.compact
        ordered_members = [] if ordered_members.nil?
        curation_concern.ordered_members = ordered_members
        curation_concern.save!( validate: false )
        add_id_fixed curation_concern.id
      end
    end

  end

end
