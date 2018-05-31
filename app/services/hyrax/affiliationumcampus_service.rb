module Hyrax
  class AffiliationumcampusService < QaSelectService
    def initialize
      super('contributor_affiliationumcampus')
    end

    def include_current_value(value, _index, render_options, html_options)
      unless value.blank? || active?(value)
        html_options[:class] << ' force-select'
        render_options += [[label(value), value]]
      end
      [render_options, html_options]
    end
  end
end