# frozen_string_literal: true

module Deepblue

  module TotalFileSizeWorkBehavior

    # Calculate the size of all the files in the work
    # @return [Integer] the size in bytes
    def size_of_work
      work_id = id
      file_size_field = 'file_size_lts'
      member_ids_field = 'member_ids_ssim'
      argz = { fl: "id, #{file_size_field}",
               fq: "{!join from=#{member_ids_field} to=id}id:#{work_id}",
               rows: 10_000 }
      files = ::FileSet.search_with_conditions( {}, argz )
      files.reduce(0) { |sum, f| sum + f[file_size_field].to_i }
    rescue RSolr::Error::Http => e  # TODO: figure out why the work_show_presenter_spec#itemtype throws this error
      # ignore and return an zero
      0
    end

    def total_file_size_add_file_set( _file_set )
      update_total_file_size
    end

    def total_file_size_add_file_set!( _file_set )
      update_total_file_size!
    end

    def total_file_size_human_readable
      total = total_file_size
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( total, precision: 3 )
    end

    def total_file_size_subtract_file_set( _file_set )
      update_total_file_size
    end

    def total_file_size_subtract_file_set!( _file_set )
      update_total_file_size!
    end

    def update_total_file_size
      total = size_of_work
      self.total_file_size = total
    end

    def update_total_file_size!
      update_total_file_size
      save( validate: false )
    end

    private

      # TODO: rename this method
      def file_size_from_file_set( file_set )
        return 0 if file_set.nil?
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
          save( validate: false )
        elsif 0 != file_size
          total_file_size_add file_size
          save( validate: false )
        end
      end

      def total_file_size_set( file_size )
        self.total_file_size = file_size
      end

  end

end
