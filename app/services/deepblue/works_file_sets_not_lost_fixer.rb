# frozen_string_literal: true

module Deepblue

  class WorksFileSetsNotLostFixer < AbstractFixer

    mattr_accessor :works_file_sets_not_lost_fixer_debug_verbose,
                   default: FindAndFixService.works_file_sets_not_lost_fixer_debug_verbose

    PREFIX = 'WorksFileSetsNotLostFixer: '

    def self.fix( curation_concern:, msg_handler: nil )
      msg_handler ||= MessageHandler.msg_handler_for_task
      fixer = WorksFileSetsNotLostFixer.new( msg_handler: msg_handler )
      fixer.fix( curation_concern: curation_concern ) if fixer.fix_include?( curation_concern: curation_concern )
    end

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      super( filter: filter, prefix: PREFIX, msg_handler: msg_handler )
    end

    def debug_verbose
      works_file_sets_not_lost_fixer_debug_verbose || msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "curation_concern.id=#{curation_concern.id}",
      #                                        "" ] if debug_verbose
      return false unless curation_concern.respond_to? :file_sets
      return false unless lost_and_found_work.present?
      super( curation_concern: curation_concern )
    end

    def fix( curation_concern: )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "curation_concern.id=#{curation_concern.id}",
      #                                        "" ] if debug_verbose
      # msg_handler ||= @msg_handler

      return unless lost_and_found_work.is_a? DataSet
      lost_and_found_ids = lost_and_found_work.file_set_ids
      fixed = false
      curation_concern.file_sets.each do |fs|
        if lost_and_found_ids.include? fs.id
          msg_verbose "FileSet #{fs.id} is in lost and found #{lost_and_found_work.id}"
          lost_and_found_work.ordered_members.delete fs
          lost_and_found_work.members.delete fs
          lost_and_found_work.save!( validate: false )
          lost_and_found_work.reload
          fixed = true
        end
      end
      add_id_fixed curation_concern.id if fixed
    end

    def lost_and_found_work
      @lost_and_found_work ||= FindAndFixService.lost_and_found_work
    end

  end

end
