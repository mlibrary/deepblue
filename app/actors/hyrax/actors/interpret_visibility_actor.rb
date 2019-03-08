
require File.join(Gem::Specification.find_by_name("hyrax").full_gem_path, "app/actors/hyrax/actors/interpret_visibility_actor.rb")

module Hyrax

  module Actors

    # monkey patch to allow embargo_release_date to be in the past
    class InterpretVisibilityActor < AbstractActor

      private

        # When specified, validate embargo is a future date that complies with AdminSet template requirements (if any)
        def validate_embargo(env, intention, attributes, template)
          return true unless intention.wants_embargo?

          embargo_release_date = parse_date(attributes[:embargo_release_date])
          # Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
          #                                      Deepblue::LoggingHelper.called_from,
          #                                      "before test",
          #                                      "attributes=#{attributes}",
          #                                      "embargo_release_date=#{embargo_release_date}" ]

          valid_embargo_release_date = DeepBlueDocs::Application.config.embargo_enforce_future_release_date ? valid_future_date?(env, embargo_release_date) : true
          # valid_template_embargo_date = valid_template_embargo_date?(env, embargo_release_date, template)
          # valid_template_visibility_after_embargo = valid_template_visibility_after_embargo?(env, attributes, template)
          # Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
          #                                      Deepblue::LoggingHelper.called_from,
          #                                      "after test",
          #                                      "valid_embargo_release_date=#{valid_embargo_release_date}",
          #                                      "valid_template_embargo_date=#{valid_template_embargo_date}",
          #                                      "valid_template_visibility_after_embargo=#{valid_template_visibility_after_embargo}" ]

          # When embargo required, date must be in future AND matches any template requirements
          return true if valid_embargo_release_date &&
                         valid_template_embargo_date?(env, embargo_release_date, template) &&
                         valid_template_visibility_after_embargo?(env, attributes, template)

          env.curation_concern.errors.add(:visibility, 'When setting visibility to "embargo" you must also specify embargo release date.') if embargo_release_date.blank?
          false
        end

    end

  end

end
