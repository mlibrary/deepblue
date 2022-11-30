# frozen_string_literal: true

module Deepblue

  class WorksTotalFileSizeFixer < AbstractFixer

    mattr_accessor :works_total_file_size_fixer_debug_verbose,
                   default: FindAndFixService.works_total_file_size_fixer_debug_verbose

    PREFIX = 'WorksTotalFileSizeFixer: '

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "" ] if works_total_file_size_fixer_debug_verbose && msg_handler.debug_verbose
      super( filter: filter, prefix: PREFIX, msg_handler: msg_handler )
    end

    def debug_verbose
      works_total_file_size_fixer_debug_verbose && msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      msg_handler.bold_debug [ msg_handler.here,
                                             msg_handler.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if debug_verbose
      return false unless curation_concern.respond_to? :file_sets
      return super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "curation_concern.id=#{curation_concern.id}",
                               "" ] if debug_verbose
      msg_handler.msg_verbose "fix work #{curation_concern.id} total file size"
      unless FindAndFixHelper.valid_file_sizes?( curation_concern: curation_concern, msg_handler: msg_handler )
        msg_verbose "Update total file size for work #{curation_concern.id}."
        FindAndFixHelper.fix_file_sizes( curation_concern: curation_concern, msg_handler: msg_handler )
      end
    end

  end

end

