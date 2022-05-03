# frozen_string_literal: true

module Umrdr

  module UmrdrWorkBehavior

    mattr_accessor :umrdr_work_behavior_debug_verbose, default: Rails.configuration.umrdr_work_behavior_debug_verbose

    extend ActiveSupport::Concern

    def globus_complete?
      ::GlobusJob.copy_complete? id
    end

    def globus_prepping?
      ::GlobusJob.files_prepping? id
    end

    def globus_clean_download( start_globus_copy_after_clean: false )
      return unless ( globus_complete? || globus_prepping? )
      ::GlobusCleanJob.perform_later( id, clean_download: true, start_globus_copy_after_clean: start_globus_copy_after_clean )
    end

    def globus_clean_download_then_recopy
      return unless ( globus_complete? || globus_prepping? )
      ::GlobusCleanJob.perform_later( id, clean_download: true, start_globus_copy_after_clean: true )
    end

    def read_me?
      read_me_file_set_id.present?
    end

    # def read_me_text
    #   return nil
    # end

    def read_me_delete( file_set: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "read_me_file_set_id=#{read_me_file_set_id}",
                                             "file_set.id=#{file_set.id}",
                                             "" ] if umrdr_work_behavior_debug_verbose
      return unless Array( read_me_file_set_id ).first == file_set.id
      self[:read_me_file_set_id] = nil
      save!( validate: false )
    end

    def read_me_update( file_set: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "read_me_file_set_id=#{read_me_file_set_id}",
                                             "file_set.id=#{file_set.id}",
                                             "" ] if umrdr_work_behavior_debug_verbose
      return if Array( read_me_file_set_id ).first == file_set.id
      self[:read_me_file_set_id] = file_set.id
      save!( validate: false )
    end

  end

end
