
module Hyrax

  class FundedbyService < QaSelectService

    def initialize
      super('fundedbys' )
    end

    def include_current_value( value, _index, render_options, html_options )
      unless value.blank? || active?(value)
        html_options[:class] << ' force-select'
        render_options += [[label(value), value]]
      end
      [render_options, html_options]
    end

  end

end
