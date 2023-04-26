# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module Blacklight
      module Rendering
        class PipelineJsonExtractor < ::Blacklight::Rendering::AbstractStep
          def render
            # FIXME: OrcidHelper.json_fields should be a configuration option
            val = OrcidHelper.json_fields.include?(config.itemprop&.to_sym) ? parsed_values : values

            next_step(val)
          end

          protected

            def parsed_values
              JSON.parse(values.first).pluck("#{config.itemprop}_name")
            rescue JSON::ParserError
              values
            end
        end
      end
    end
  end
end
