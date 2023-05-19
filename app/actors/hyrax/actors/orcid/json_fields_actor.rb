# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Actors
    module Orcid
      class JSONFieldsActor < Hyrax::Actors::AbstractActor
        def create(env)
          debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_actors_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "" ] if debug_verbose
          jsonify_fields(env) && next_actor.create(env)
        end

        def update(env)
          debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_actors_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "env=#{env}",
                                                 "" ] if debug_verbose
          jsonify_fields(env) && next_actor.update(env)
        end

        private

          # rubocop:disable Metrics/AbcSize
          def jsonify_fields(env)
            return true
            # skip this for now
            env.curation_concern.class.json_fields.each do |field|
              if name_blank?(field, env.attributes[field]) || recursive_blank?(env.attributes[field])
                #puts "jsonify_fields delete field #{field}"
                env.attributes.delete(field)
                next
              end

              if env.attributes[field].is_a? Array
                env.attributes[field].reject! { |o| name_blank?(field, o) || recursive_blank?(o) }
                if env.attributes[field].blank?
                  env.attributes.delete(field)
                  next
                end
              end
              env.attributes[field] = env.attributes[field].to_json
              #puts "json version env.attributes[#{field}]=#{env.attributes[field]}"

              #puts "env.curation_concern.class.multiple?(#{field})=#{env.curation_concern.class.multiple?(field)}"
              next unless env.curation_concern.class.multiple?(field)
              env.attributes[field] = Array(env.attributes[field])
              #puts "json version env.attributes[#{field}]=#{env.attributes[field]}"

            end
          end
          # rubocop:enable Metrics/AbcSize

          def name_blank?(field, obj)
            # FIXME: OrcidHelper.json_fields should be a configuration option
            return false unless field.in? ::Hyrax::Orcid::OrcidHelper.json_fields

            # recursive_blank?(Array(obj).map { |o| o.reject { |k, _v| k == "#{field}_name_type" } })
            rv = recursive_blank?(Array(obj).map { |o| do_reject( field, o ) })
            #puts "name_blank? rv=#{rv}"
          end

          def do_reject( field, obj )
            case obj
            when Hash
              obj.reject { |k, _v| k == "#{field}_name_type" }
            else
              obj
            end
          end

          def recursive_blank?(obj)
            case obj
            when Hash
              obj.values.all? { |o| recursive_blank?(o) }
            when Array
              obj.all? { |o| recursive_blank?(o) }
            else
              obj.blank?
            end
          end
      end
    end
  end
end
