# frozen_string_literal: true

module Umrdr
  module UmrdrWorkBehavior
    extend ActiveSupport::Concern

    # def total_file_size_add_file_set( file_set )
    #   size = file_size_from_file_set file_set
    #   total_file_size_add size
    # end
    #
    # def total_file_size_add_file_set!( file_set )
    #   size = file_size_from_file_set file_set
    #   total_file_size_add! size
    # end
    #
    # def total_file_size_human_readable
    #   total = self.total_file_size
    #   ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( total, precision: 3 )
    # end
    #
    # def total_file_size_subtract_file_set( file_set )
    #   size = file_size_from_file_set file_set
    #   total_file_size_add -size
    # end
    #
    # def total_file_size_subtract_file_set!( file_set )
    #   size = file_size_from_file_set file_set
    #   total_file_size_add! -size
    # end
    #
    # def update_total_file_size
    #   ## TODO: probably can do this through self.file_sets
    #   total = 0
    #   ids = file_set_ids
    #   ids.map do |fid|
    #     af = ActiveFedora::Base.find fid
    #     unless af.nil?
    #       file = af.original_file
    #       total += file.size unless file.nil?
    #     end
    #   end
    #   self.total_file_size = total
    #   #total_file_size_human_readable = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( total, precision: 3 )
    # end
    #
    # def update_total_file_size!
    #   update_total_file_size
    #   save!
    # end
    #
    # private
    #
    # def file_size_from_file_set( file_set )
    #   file = file_set.file
    #   if file.nil?
    #     file = file_set.original_file
    #   end
    #   file_size = 0
    #   if file.nil?
    #     Rails.logger.warn "UmrdrWorkBehavior file_set file is nil"
    #   else
    #     file_size = file.size
    #   end
    #   file_size
    # end
    #
    # def total_file_size_add( file_size )
    #   current_total_size = total_file_size
    #   current_total_size = ( current_total_size.nil? ? 0 : current_total_size ) + file_size
    #   if current_total_size < 0
    #     current_total_size = 0
    #   end
    #   self.total_file_size = current_total_size
    # end
    #
    # def total_file_size_add!( file_size )
    #   if 1 == file_sets.size
    #     total_file_size_set file_size
    #     save!
    #   elsif 0 != file_size
    #     total_file_size_add file_size
    #     save!
    #   end
    # end
    #
    # def total_file_size_set( file_size )
    #   self.total_file_size = file_size
    # end

  end
end