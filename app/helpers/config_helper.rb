# frozen_string_literal: true

module ConfigHelper

  def self.human_readable_size( value, precision: 3 )
    ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: precision )
  end

end
