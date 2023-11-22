# frozen_string_literal: true

module Umrdr

  module UmrdrWorkBehavior

    mattr_accessor :umrdr_work_behavior_debug_verbose, default: Rails.configuration.umrdr_work_behavior_debug_verbose

    extend ActiveSupport::Concern

    def globus_complete?
      ::Deepblue::GlobusService.globus_copy_complete? id
    end

    def globus_prepping?
      ::Deepblue::GlobusService.globus_files_prepping? id
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

    def ticket?
      ticket.present?
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

    # def link_file_set( file_set:, force: false )
    #   return false if file_set.blank?
    #   if force
    #     representative = file_set if representative_id
    #     thumbnail = file_set if thumbnail_id
    #     return true
    #   end
    #   modified = ( representative_id.blank? || thumbnail_id.blank? )
    #   representative = file_set if representative_id.blank?
    #   thumbnail = file_set if thumbnail_id.blank?
    #   return modified
    # end
    #
    # def link_file_set!( file_set:, force: false )
    #   return if file_set.blank?
    #   work.save! if link_file_set( file_set: file_set, force: force )
    # end
    #
    # def unlink_file_set( file_set: )
    #   return if file_set.blank?
    #   total_file_size_subtract_file_set file_set
    #   read_me_delete( file_set: file_set )
    #   fid = file_set_id
    #   return unless ( thumbnail_id == fid || representative_id == fid || rendering_ids.include?(fid) )
    #   thumbnail = nil if thumbnail_id == fid
    #   representative = nil if work.representative_id == fid
    #   rendering_ids -= [fid]
    # end
    #
    # def unlink_file_set!( file_set: )
    #   return if file_set.blank?
    #   unlink_file_set( file_set: file_set )
    #   work.save!
    # end

  end

end
