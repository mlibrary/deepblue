module Umrdr
  module FileSetBehavior
    extend ActiveSupport::Concern

    def update_parent()
      parent.total_file_size_add_file_set!( self ) unless parent.nil?
    end

  end
end
