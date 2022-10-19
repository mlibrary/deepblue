# frozen_string_literal: true

module Deepblue

  class FileSetsLostAndFoundFixer < AbstractFixer

    mattr_accessor :file_sets_lost_and_found_fixer_debug_verbose,
                   default: FindAndFixService.file_sets_lost_and_found_fixer_debug_verbose

    PREFIX = 'FileSet lost and found: '

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      super( msg_handler: msg_handler, filter: filter, prefix: PREFIX )
    end

    def debug_verbose
      file_sets_lost_and_found_fixer_debug_verbose && msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      return false unless curation_concern.parent.blank?
      return super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      work = lost_and_found_work
      if work.is_a? DataSet
        msg_verbose "FileSet #{curation_concern.id} added to lost and found work #{work.id}"
        work.ordered_members << curation_concern
        work.save!( validate: false )
        work.reload
      else
        msg_verbose "FileSet #{curation_concern.id} has no parent. Create DataSet with title #{lost_and_found_work_title}"
      end
    end

    def lost_and_found_work
      @lost_and_found_work ||= init_lost_and_found_work
    end

    def lost_and_found_work_title
      FindAndFixService.find_and_fix_file_sets_lost_and_found_work_title
    end

    def init_lost_and_found_work
      solr_query = "+generic_type_sim:Work AND +title_tesim:#{lost_and_found_work_title}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "lost_and_found_work_title=#{lost_and_found_work_title}",
                                             "solr_query=#{solr_query}",
                                             "" ], bold_puts: msg_handler.to_console if file_sets_lost_and_found_fixer_debug_verbose
      results = ::Hyrax::SolrService.query( solr_query, rows: 10 )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "results.class.name=#{results.class.name}",
                                             "results=#{results}",
                                             "results&.size=#{results&.size}",
                                             "" ], bold_puts: msg_handler.to_console if file_sets_lost_and_found_fixer_debug_verbose
      return 'not found' unless results.present?
      # results are an array of solr documents, extract the id from the first one and look it up
      id = results[0].id
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "" ], bold_puts: msg_handler.to_console if file_sets_lost_and_found_fixer_debug_verbose
      result = results[0]
      work = PersistHelper.find(id)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work=#{work}",
                                             "" ], bold_puts: msg_handler.to_console if file_sets_lost_and_found_fixer_debug_verbose
      return work
    end

  end

end
