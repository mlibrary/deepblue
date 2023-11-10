# frozen_string_literal: true

module Aptrust

  module AptrustBehavior

    def self.arg_init( attr, default )
      attr ||= default
      return attr
    end

    def self.arg_init_squish(attr, default, squish: 255 )
      attr ||= default
      if attr.blank? && squish.present?
        attr = ''
      else
        attr = attr.squish[0..squish]
      end
      return attr
    end

  end

end
