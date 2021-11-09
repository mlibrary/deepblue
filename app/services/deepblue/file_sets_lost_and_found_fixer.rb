# frozen_string_literal: true

module Deepblue

  class FileSetsLostAndFoundFixer < ::Deepblue::AbstractFixer

    mattr_accessor :file_sets_lost_and_found_fixer_debug_verbose,
                   default: ::Deepblue::FindAndFixService.file_sets_lost_and_found_fixer_debug_verbose

    PREFIX = 'FileSet lost and found: '

    def initialize( debug_verbose: file_sets_lost_and_found_fixer_debug_verbose,
                    filter: Deepblue::FindAndFixService.find_and_fix_default_filter,
                    task: false,
                    verbose: Deepblue::FindAndFixService.find_and_fix_default_verbose )

      super( debug_verbose: debug_verbose, filter: filter, prefix: PREFIX, task: task, verbose: verbose )
    end

    def fix_include?( curation_concern:, messages: )
      return false unless curation_concern.parent.blank?
      return super( curation_concern: curation_concern, messages: messages )
    end

    def fix( curation_concern:, messages: )
      work = lost_and_found_work
      if work.is_a? DataSet
        add_msg messages, "FileSet #{curation_concern.id} added to lost and found work #{work.id}" if verbose
        work.ordered_members << curation_concern
        work.save!( validate: false )
        work.reload
      else
        add_msg messages, "FileSet #{curation_concern.id} has no parent. Create DataSet with title #{lost_and_found_work_title}" if verbose
      end
    end

    def lost_and_found_work
      @lost_and_found_work ||= init_lost_and_found_work
    end

    def lost_and_found_work_title
      ::Deepblue::FindAndFixService.find_and_fix_file_sets_lost_and_found_work_title
    end

    def init_lost_and_found_work
      solr_query = "+generic_type_sim:Work AND +title_tesim:#{lost_and_found_work_title}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "solr_query=#{solr_query}",
                                             "" ], bold_puts: task if file_sets_lost_and_found_fixer_debug_verbose
      results = ::ActiveFedora::SolrService.query( solr_query, rows: 10 )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "results.class.name=#{results.class.name}",
                                             "results=#{results}",
                                             "" ], bold_puts: task if file_sets_lost_and_found_fixer_debug_verbose
      return 'not found' unless results.present?
      return results if results.is_a? DataSet
      result = results[0] if results
      return result
    end

  end

end
