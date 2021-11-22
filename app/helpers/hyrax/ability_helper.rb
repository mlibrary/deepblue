module Hyrax
  module AbilityHelper

    mattr_accessor :ability_helper_debug_verbose, default: Rails.configuration.ability_helper_debug_verbose

    def visibility_options(variant)
      options = [
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      ]
      case variant
      when :restrict
        options.delete_at(0)
        options.delete_at(0)
        options.reverse!
      when :loosen
        options.delete_at(1)
        options.delete_at(1)
      end
      options.map { |value| [visibility_text(value), value] }
    end

    def visibility_badge(value)
      PermissionBadge.new(value).render
    end

    def render_visibility_link(document)
      # Admin Sets do not have a visibility property.
      return if document.respond_to?(:admin_set?) && document.admin_set?

      # Anchor must match with a tab in
      # https://github.com/samvera/hyrax/blob/master/app/views/hyrax/base/_guts4form.html.erb#L2
      path = if document.collection?
               hyrax.edit_dashboard_collection_path(document, anchor: 'share')
             else
               edit_polymorphic_path([main_app, document], anchor: 'share')
             end
      link_to(
        visibility_badge(document.visibility),
        path,
        id: "permission_#{document.id}",
        class: 'visibility-link'
      )
    end

    private

      def visibility_text(value)
        return institution_name if value == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        t("hyrax.visibility.#{value}.text")
      end
  end
end
