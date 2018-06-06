
module Hyrax

  class SubjectDisciplineService < QaSelectService

    def initialize
      super('subject_disciplines' )
    end

    def include_current_value( value, _index, render_options, html_options )
      if value.present? # || active?(value)
        html_options[:class] << ' force-select'
        render_options += [[label(value), value]]
      end
      [render_options, html_options]
    end

  end

end
