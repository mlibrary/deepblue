# frozen_string_literal: true

module Deepblue

  class WorksTotalFileSizeFixer < AbstractFixer

    mattr_accessor :works_total_file_size_fixer_debug_verbose,
                   default: FindAndFixService.works_total_file_size_fixer_debug_verbose

    PREFIX = 'WorksTotalFileSizeFixer: '

    def initialize( debug_verbose: works_ordered_members_file_sets_size_fixer_debug_verbose,
                    filter: FindAndFixService.find_and_fix_default_filter,
                    task: false,
                    verbose: FindAndFixService.find_and_fix_default_verbose )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ], bold_puts: task if works_total_file_size_fixer_debug_verbose

      super( debug_verbose: debug_verbose,
             filter: filter,
             prefix: PREFIX,
             task: task,
             verbose: verbose )
    end

    def fix_include?( curation_concern:, msg_handler: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ], bold_puts: task if works_total_file_size_fixer_debug_verbose
      @msg_handler ||= msg_handler
      return false unless curation_concern.respond_to? :file_sets
      return super( curation_concern: curation_concern, msg_handler: msg_handler )
    end

    def fix( curation_concern:, msg_handler: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ], bold_puts: task if works_total_file_size_fixer_debug_verbose
      @msg_handler ||= msg_handler
      msg_handler.msg_verbose "fix work #{curation_concern.id} total file size"
      unless FindAndFixHelper.valid_file_sizes?( curation_concern: curation_concern,
                                             fixer: self,
                                             task: false,
                                             debug_verbose: works_total_file_size_fixer_debug_verbose )

        add_msg "Update total file size for work #{curation_concern.id}." # if verbose
        FindAndFixHelper.fix_file_sizes( curation_concern: curation_concern,
                                         fixer: self,
                                         task: false,
                                         debug_verbose: works_total_file_size_fixer_debug_verbose )
      end

    end

  end

end

