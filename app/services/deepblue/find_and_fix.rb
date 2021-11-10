# frozen_string_literal: true

module Deepblue

  class FindAndFix

    mattr_accessor :find_and_fix_debug_verbose, default: FindAndFixService.find_and_fix_debug_verbose

    attr_accessor :find_and_fix_collections_fixers
    attr_accessor :find_and_fix_file_sets_fixers
    attr_accessor :find_and_fix_works_fixers

    attr_accessor :debug_verbose, :filter, :ids_fixed, :messages, :task, :verbose

    def initialize( debug_verbose: find_and_fix_debug_verbose,
                    filter: nil,
                    messages: [],
                    task: false,
                    verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "filter=#{filter}",
                                             "messages=#{messages}",
                                             "task=#{task}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: task if debug_verbose
      @debug_verbose = debug_verbose
      @task = task
      @filter = filter
      @messages = messages
      @verbose = verbose
      @ids_fixed = {}
      init_find_and_fix_collections
      init_find_and_fix_works
      init_find_and_fix_file_sets
    end

    def init_fixer( fixer_class_name )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "fixer_class_name=#{fixer_class_name}",
                                             "" ], bold_puts: task if debug_verbose
      fixer = nil
      begin
        fixer_class = fixer_class_name.constantize
        fixer = fixer_class.new( filter: filter, verbose: verbose, debug_verbose: debug_verbose, task: task )
        unless fixer.respond_to? :fix
          messages << "Error: Expected #{fixer_class_name} to respond to 'fix'"
          return nil
        end
        unless fixer.respond_to? :fix_include?
          messages << "Error: Expected #{fixer_class_name} to respond to 'fix_include?'"
          return nil
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        messages << "Error while creating fixer #{fixer_class_name}: #{e.message} at #{e.backtrace[0]}"
      end
      return fixer
    end

    def init_find_and_fix_collections
      @find_and_fix_collections_fixers = []
      FindAndFixService.find_and_fix_over_collections.each do |fixer_class_name|
        fixer = init_fixer fixer_class_name
        @find_and_fix_collections_fixers << fixer unless fixer.nil?
      end
    end

    def init_find_and_fix_file_sets
      @find_and_fix_file_sets_fixers = []
      FindAndFixService.find_and_fix_over_file_sets.each do |fixer_class_name|
        fixer = init_fixer fixer_class_name
        @find_and_fix_file_sets_fixers << fixer unless fixer.nil?
      end
    end

    def init_find_and_fix_works
      @find_and_fix_works_fixers = []
      FindAndFixService.find_and_fix_over_works.each do |fixer_class_name|
        fixer = init_fixer fixer_class_name
        @find_and_fix_works_fixers << fixer unless fixer.nil?
      end
    end

    def find_and_fix_collect_results
      find_and_fix_file_sets_fixers.each do |fixer|
        fixer.ids_fixed.each do |id|
          @ids_fixed[id] = true
        end
      end
      find_and_fix_works_fixers.each do |fixer|
        fixer.ids_fixed.each do |id|
          @ids_fixed[id] = true
        end
      end
      find_and_fix_collections_fixers.each do |fixer|
        fixer.ids_fixed.each do |id|
          @ids_fixed[id] = true
        end
      end
    end

    def find_and_fix_over( curation_concern:, fixers:, prefix: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ], bold_puts: task if debug_verbose
      fixers.each do |fixer|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "fixer.class.name=#{fixer.class.name}",
                                               "#{prefix} id=#{curation_concern.id}",
                                               "" ], bold_puts: task if debug_verbose
        begin
          next unless fixer.fix_include?( curation_concern: curation_concern, messages: messages )
          fixer.fix( curation_concern: curation_concern, messages: messages )
        rescue Exception => e # rubocop:disable Lint/RescueException
          messages << "Error while processing #{fixer.class.name} - #{prefix} #{curation_concern.id}: #{e.message} at #{e.backtrace[0]}"
        end
      end
    end

    def find_and_fix_over_collections
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ], bold_puts: task if debug_verbose
      return unless find_and_fix_collections_fixers.present?
      Collection.all.each do |curation_concern|
        find_and_fix_over( curation_concern: curation_concern,
                           fixers: find_and_fix_collections_fixers,
                           prefix: 'Collection' )
      end
    end

    def find_and_fix_over_file_sets
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ], bold_puts: task if debug_verbose
      return unless find_and_fix_file_sets_fixers.present?
      prefix = 'FileSet'
      FileSet.all.each do |curation_concern|
        find_and_fix_over( curation_concern: curation_concern,
                           fixers: find_and_fix_file_sets_fixers,
                           prefix: 'FileSet' )
      end
    end

    def find_and_fix_over_works
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "find_and_fix_works_fixers.present?=#{find_and_fix_works_fixers.present?}",
                                             "" ], bold_puts: task if debug_verbose
      return unless find_and_fix_works_fixers.present?
      prefix = 'DataSet'
      DataSet.all.each do |curation_concern|
        find_and_fix_over( curation_concern: curation_concern,
                           fixers: find_and_fix_works_fixers,
                           prefix: 'DataSet' )
      end
    end

    def run
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "filter=#{filter}",
                                             "messages=#{messages}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: task if debug_verbose
      messages << "Started: #{DateTime.now}"
      find_and_fix_over_file_sets
      find_and_fix_over_works
      find_and_fix_over_collections
      find_and_fix_collect_results
      messages << "Finished: #{DateTime.now}"
      return unless verbose && task
      puts "Finished."
      messages.each do |msg|
        puts msg
      end
      ids_fixed.each_key do |id|
        puts id
      end
    end

  end

end
