# frozen_string_literal: true

module Deepblue

  module FindAndFixService

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :find_and_fix_service_debug_verbose,             default: false
    mattr_accessor :abstract_fixer_debug_verbose,                   default: false
    mattr_accessor :file_sets_embargo_fixer_debug_verbose,          default: false
    mattr_accessor :file_sets_file_size_fixer_debug_verbose,        default: false
    mattr_accessor :file_sets_lost_and_found_fixer_debug_verbose,   default: false
    mattr_accessor :file_sets_visibility_fixer_debug_verbose,       default: false
    mattr_accessor :find_and_fix_job_debug_verbose,                 default: false
    mattr_accessor :find_and_fix_empty_file_sizes_debug_verbose,    default: false
    mattr_accessor :find_and_fix_job_debug_verbose,                 default: false
    mattr_accessor :works_file_sets_not_lost_fixer_debug_verbose,   default: false
    mattr_accessor :works_file_sets_visibility_fixer_debug_verbose, default: false
    mattr_accessor :works_ordered_members_file_sets_size_fixer_debug_verbose, default: false
    mattr_accessor :works_ordered_members_nils_fixer_debug_verbose, default: false
    mattr_accessor :works_total_file_size_fixer_debug_verbose,      default: false

    mattr_accessor :find_and_fix_default_filter,   default: nil
    mattr_accessor :find_and_fix_default_verbose,  default: true
    mattr_accessor :find_and_fix_over_collections, default: []
    mattr_accessor :find_and_fix_over_file_sets,   default: [ 'Deepblue::FileSetsEmbargoFixer',
                                                              'Deepblue::FileSetsFileSizeFixer',
                                                              'Deepblue::FileSetsLostAndFoundFixer',
                                                              'Deepblue::FileSetsVisibilityFixer' ]
    mattr_accessor :find_and_fix_over_works,       default: [ 'Deepblue::WorksOrderedMembersNilsFixer',
                                                              'Deepblue::WorksOrderedMembersFileSetsSizeFixer',
                                                              'Deepblue::WorksTotalFileSizeFixer',
                                                              'Deepblue::WorksFileSetsNotLostFixer',
                                                              'Deepblue::WorksFileSetsVisibilityFixer' ]

    mattr_accessor :find_and_fix_file_sets_lost_and_found_work_title, default: 'DBD_Find_and_Fix_FileSets_Lost_and_Found'

    mattr_accessor :find_and_fix_subscription_id, default: 'find_and_fix_subscription'

    def self.find_and_fix( filter_date_begin: nil, filter_date_end: nil, msg_handler: )
      debug_verbose = msg_handler.debug_verbose && find_and_fix_service_debug_verbose
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "filter_date_begin=#{filter_date_begin}",
                               "filter_date_end=#{filter_date_end}",
                               "msg_handler=#{msg_handler}",
                               "" ] if debug_verbose
      filter_date = nil
      if filter_date_begin.present? || filter_date_end.present?
        filter_date = FindCurationConcernFilterDate.new(begin_date: filter_date_begin,
                                                        end_date: filter_date_end )
        msg_handler.msg "Filter dates between #{filter_date.begin_date} and #{filter_date.end_date}."
      end
      fixer = FindAndFix.new( filter: filter_date, msg_handler: msg_handler )
      FindAndFixHelper.duration( label: "Run duration: ", msg_handler: msg_handler ) { fixer.run }
    end

    def self.lost_and_found_work( msg_handler: nil )
      solr_query = "+generic_type_sim:Work AND +title_tesim:#{find_and_fix_file_sets_lost_and_found_work_title}"
      to_console = msg_handler.nil? ? false : msg_handler.to_console
      debug_verbose = msg_handler.nil? ? false : msg_handler.debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "lost_and_found_work_title=#{find_and_fix_file_sets_lost_and_found_work_title}",
                                             "solr_query=#{solr_query}",
                                             "" ], bold_puts: to_console if debug_verbose
      results = ::Hyrax::SolrService.query( solr_query, rows: 10 )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "results.class.name=#{results.class.name}",
                                             "results=#{results}",
                                             "results&.size=#{results&.size}",
                                             "" ], bold_puts: to_console if debug_verbose
      return 'not found' unless results.present?
      # results are an array of solr documents, extract the id from the first one and look it up
      id = results[0].id
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "" ], bold_puts: to_console if debug_verbose
      result = results[0]
      work = PersistHelper.find(id)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work=#{work}",
                                             "" ], bold_puts: to_console if debug_verbose
      return work
    end

    def self.work_find_and_fix( id:, msg_handler: )
      debug_verbose = msg_handler.debug_verbose && find_and_fix_service_debug_verbose
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "id=#{id}",
                               "msg_handler=#{msg_handler}",
                               "" ] if debug_verbose
      fixer = FindAndFix.new( id: id, msg_handler: msg_handler )
      FindAndFixHelper.duration( label: "Run duration: ", msg_handler: msg_handler ) { fixer.run }
    end

  end

end
