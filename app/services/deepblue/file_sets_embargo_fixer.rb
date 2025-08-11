# frozen_string_literal: true

module Deepblue

  class FileSetsEmbargoFixer < AbstractFixer

    mattr_accessor :file_sets_embargo_fixer_debug_verbose,
                   default: FindAndFixService.file_sets_embargo_fixer_debug_verbose

    PREFIX = 'FileSet embargo: '

    def self.fix( curation_concern:, msg_handler: nil )
      msg_handler ||= MessageHandler.msg_handler_for_task
      fixer = FileSetsEmbargoFixer.new( msg_handler: msg_handler )
      fixer.fix( curation_concern: curation_concern ) if fixer.fix_include?( curation_concern: curation_concern )
    end

    def initialize( filter: FindAndFixService.find_and_fix_default_filter, msg_handler: )
      super( filter: filter, msg_handler: msg_handler, prefix: PREFIX )
    end

    def debug_verbose
      file_sets_embargo_fixer_debug_verbose || msg_handler.debug_verbose
    end

    def fix_include?( curation_concern: )
      rv = false
      begin # until true for break
        unless curation_concern.parent.present?
          rvReason = "not cc parent present"
          break
        end
        if curation_concern.ingesting?
          rvReason = "cc ingesting"
          break
        end
        rv = super( curation_concern: curation_concern )
        rvReason = "super.fix_include?"
        # if filter.nil?
        #   rv = true
        #   rvReason = "filter.nil"
        #   break
        # end
        # if curation_concern.date_modified.present?
        #   rv = filter.include?( curation_concern.date_modified )
        #   rvReason = "cc filter.include?( #{curation_concern.date_modified} )"
        #   break
        # end
        # rv = default_filter_in
        # rvReason = "default_filter_in"
      end until true # for break
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "rv=#{rv}",
                                             "rvReason=#{rvReason}",
                                             "" ] if file_sets_embargo_fixer_debug_verbose
      return rv
    end

    def fix( curation_concern: )
      parent = curation_concern.parent
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "curation_concern.visibility=#{curation_concern.visibility}",
                                             "parent.id=#{parent.id}",
                                             "" ] if file_sets_embargo_fixer_debug_verbose
      if curation_concern.embargo.present?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.embargo=#{curation_concern.embargo}",
                                               "curation_concern.embargo&.embargo_release_date.present?=#{curation_concern.embargo&.embargo_release_date.present?}",
                                               "" ] if file_sets_embargo_fixer_debug_verbose
        if parent.embargo.blank?
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "curation_concern.id=#{curation_concern.id} is embargoed, but its parent embargo is blank, clear its embargo",
                                                 "" ] if file_sets_embargo_fixer_debug_verbose
          curation_concern.embargo = nil
          # curation_concern.date_modified = DateTime.now
          # curation_concern.save!( validate: false )
          curation_concern.metadata_touch
          add_id_fixed curation_concern.id
          msg_verbose "FileSet #{curation_concern.id} parent work #{parent.id} not in embargo, remove embargo."
        else
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "curation_concern.id=#{curation_concern.id} is not embargoed, nor is its parent, skip",
                                                 "" ] if file_sets_embargo_fixer_debug_verbose
        end
      elsif curation_concern.embargo.blank? && parent&.embargo&.embargo_release_date.present?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.id=#{curation_concern.id} embargo is blank, but its parent has an embargo, apply the embargo",
                                               "parent.id=#{parent.id}",
                                               "" ] if file_sets_embargo_fixer_debug_verbose
        apply_embargo( curation_concern )
        curation_concern.metadata_touch
        add_id_fixed curation_concern.id
        msg_verbose "FileSet #{curation_concern.id} parent work #{parent.id} in embargo, adding embargo."
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "after file set embargo fixed",
                                               "" ] if file_sets_embargo_fixer_debug_verbose
      end
    end

    def apply_embargo(curation_concern)
      parent = curation_concern.parent
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "parent.id=#{parent.id}",
                                             "" ] if file_sets_embargo_fixer_debug_verbose
      curation_concern.embargo_release_date = parent.embargo_release_date
      curation_concern.visibility_during_embargo = parent.visibility_during_embargo
      curation_concern.visibility_after_embargo = parent.visibility_after_embargo
    end

  end

end
