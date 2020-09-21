# frozen_string_literal: true

module Umrdr

  module UmrdrWorkBehavior

    UMRDR_WORK_BEHAVIOR_DEBUG_VERBOSE = true

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
                                             "" ] if true || UMRDR_WORK_BEHAVIOR_DEBUG_VERBOSE
      return unless Array( read_me_file_set_id ).first == file_set.id
      self[:read_me_file_set_id] = nil
      save!
    end

    def read_me_update( file_set: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "read_me_file_set_id=#{read_me_file_set_id}",
                                             "file_set.id=#{file_set.id}",
                                             "" ] if true || UMRDR_WORK_BEHAVIOR_DEBUG_VERBOSE
      return if Array( read_me_file_set_id ).first == file_set.id
      self[:read_me_file_set_id] = file_set.id
      save!
    end

    # Calculate the size of all the files in the work
    # @return [Integer] the size in bytes
    def size_of_work
      work_id = id
      file_size_field = Solrizer.solr_name(:file_size, Hyrax::FileSetIndexer::STORED_LONG)
      member_ids_field = Solrizer.solr_name('member_ids', :symbol)
      argz = { fl: "id, #{file_size_field}",
               fq: "{!join from=#{member_ids_field} to=id}id:#{work_id}",
               rows: 10_000 }
      files = ::FileSet.search_with_conditions({}, argz)
      files.reduce(0) { |sum, f| sum + f[file_size_field].to_i }
    rescue RSolr::Error::Http => e  # TODO: figure out why the work_show_presenter_spec#itemtype throws this error
      # ignore and return an zero
      0
    end

    def total_file_size_add_file_set( _file_set )
      # size = file_size_from_file_set file_set
      # total_file_size_add size
      update_total_file_size
    end

    def total_file_size_add_file_set!( _file_set )
      # size = file_size_from_file_set file_set
      # total_file_size_add! size
      update_total_file_size!
    end

    def total_file_size_human_readable
      total = total_file_size
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( total, precision: 3 )
    end

    def total_file_size_subtract_file_set( _file_set )
      # size = file_size_from_file_set file_set
      # total_file_size_add( -size )
      update_total_file_size
    end

    def total_file_size_subtract_file_set!( _file_set )
      # size = file_size_from_file_set file_set
      # total_file_size_add!( -size )
      update_total_file_size!
    end

    def update_total_file_size
      # total = 0
      # file_sets.each do |fs|
      #   file_size = file_size_from_file_set fs
      #   total += file_size
      # end
      total = size_of_work
      self.total_file_size = total
      # total_file_size_human_readable = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( total, precision: 3 )
    end

    def update_total_file_size!
      update_total_file_size
      save!
    end

    private

      def file_size_from_file_set( file_set )
        return 0 if file_set.nil?
        # return 0 if file_set.file_size.blank?
        # file_set.file_size[0].to_i
        file_set.file_size_value
      end

      def total_file_size_add( file_size )
        current_total_size = total_file_size
        current_total_size = ( current_total_size.nil? ? 0 : current_total_size ) + file_size
        current_total_size = 0 if current_total_size.negative?
        self.total_file_size = current_total_size
      end

      def total_file_size_add!( file_size )
        if 1 == file_sets.size
          total_file_size_set file_size
          save!
        elsif 0 != file_size
          total_file_size_add file_size
          save!
        end
      end

      def total_file_size_set( file_size )
        self.total_file_size = file_size
      end

  end

end
