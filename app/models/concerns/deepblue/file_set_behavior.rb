# frozen_string_literal: true

module Deepblue
  module FileSetBehavior
    extend ActiveSupport::Concern

    included do

      after_initialize :set_deepblue_file_set_defaults

      def set_deepblue_file_set_defaults
        return unless new_record?
        # self.file_size = 0
        # self.visibility = 'open'
      end

    end

    def update_parent
      parent.total_file_size_add_file_set!( self ) unless parent.nil?
    end

  end
end
