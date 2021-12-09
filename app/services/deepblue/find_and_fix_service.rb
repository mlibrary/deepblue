# frozen_string_literal: true

module Deepblue

  module FindAndFixService

    mattr_accessor :find_and_fix_service_debug_verbose,             default: false
    mattr_accessor :abstract_fixer_debug_verbose,                   default: false
    mattr_accessor :file_sets_lost_and_found_fixer_debug_verbose,   default: false
    mattr_accessor :file_sets_visibility_fixer_debug_verbose,       default: false
    mattr_accessor :find_and_fix_debug_verbose,                     default: false
    mattr_accessor :find_and_fix_job_debug_verbose,                 default: false
    mattr_accessor :works_ordered_members_file_sets_size_fixer_debug_verbose, default: false
    mattr_accessor :works_ordered_members_nils_fixer_debug_verbose, default: false

    mattr_accessor :find_and_fix_default_filter,   default: nil
    mattr_accessor :find_and_fix_default_verbose,  default: true
    mattr_accessor :find_and_fix_over_collections, default: []
    mattr_accessor :find_and_fix_over_file_sets,   default: [ 'Deepblue::FileSetsLostAndFoundFixer',
                                                              'Deepblue::FileSetsVisibilityFixer' ]
    mattr_accessor :find_and_fix_over_works,       default: [ 'Deepblue::WorksOrderedMembersNilsFixer',
                                                              'Deepblue::WorksOrderedMembersFileSetsSizeFixer' ]

    mattr_accessor :find_and_fix_file_sets_lost_and_found_work_title, default: 'DBD_Find_and_Fix_FileSets_Lost_and_Found'

    mattr_accessor :find_and_fix_subscription_id, default: 'find_and_fix_subscription'

    @@_setup_failed = false
    @@_setup_ran = false

    def self.setup
      return if @@_setup_ran == true
      @@_setup_ran = true
      begin
        yield self
      rescue Exception => e # rubocop:disable Lint/RescueException
        @@_setup_failed = true
      end
    end

    def self.find_and_fix( filter_date_begin: nil,
                           filter_date_end: nil,
                           messages:,
                           verbose: find_and_fix_default_verbose,
                           debug_verbose: find_and_fix_service_debug_verbose,
                           task: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "filter_date_begin=#{filter_date_begin}",
                                             "filter_date_end=#{filter_date_end}",
                                             "messages=#{messages}",
                                             "verbose=#{verbose}",
                                             "" ] if debug_verbose
      filter_date = nil
      messages = [] if messages.nil?
      if filter_date_begin.present? || filter_date_end.present?
        filter_date = FindAndFixCurationConcernFilterDate.new( begin_date: filter_date_begin,
                                                               end_date: filter_date_end,
                                                               debug_verbose: debug_verbose )
        messages << "Filter dates between #{filter_date.begin_date} and #{filter_date.end_date}."
      end
      fixer = FindAndFix.new( filter: filter_date,
                              messages: messages,
                              verbose: verbose,
                              debug_verbose: debug_verbose,
                              task: task )
      fixer.run
    end

  end

end
