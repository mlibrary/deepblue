# frozen_string_literal: true

module Deepblue

  module TotalFileSizeSolrDocumentBehavior
    extend ActiveSupport::Concern

    def total_file_size
      Array( self['total_file_size_lts'] ).first
    end

    def total_file_size_human_readable
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( total_file_size, precision: 3 )
    end

  end

end
