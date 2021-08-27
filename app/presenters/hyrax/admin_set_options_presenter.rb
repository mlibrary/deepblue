module Hyrax
  # Presents the options for the AdminSet widget on the create/edit form
  class AdminSetOptionsPresenter
    def initialize(service)
      @service = service
    end

    # Return AdminSet selectbox options based on access type
    # @param [Symbol] access :deposit, :read, or :edit
    def select_options(access = :deposit)
      @service.search_results(access).map do |admin_set|
        [admin_set.to_s, admin_set.id, data_attributes(admin_set)]
      end
    end


    def select_options_default_admin(access = :deposit)
      a = []
      @service.search_results(access).each do |admin_set|
        if admin_set.id == Rails.configuration.default_admin_set_id
           a << [admin_set.to_s, admin_set.id, data_attributes(admin_set)]
        end
      end
      a
    end


    def select_options_non_default_admin(access = :deposit)
      a = []
      @service.search_results(access).each do |admin_set|
        if admin_set.id != Rails.configuration.default_admin_set_id
           a << [admin_set.to_s, admin_set.id, data_attributes(admin_set)]
        end
      end
      a
    end


    private

      # Create a hash of HTML5 'data' attributes. These attributes are added to select_options and
      # later utilized by Javascript to limit new Work options based on AdminSet selected
      def data_attributes(admin_set)
        # Get permission template associated with this AdminSet (if any)
        permission_template = PermissionTemplate.find_by(source_id: admin_set.id)

        # Only add data attributes if permission template exists
        return {} unless permission_template
        attributes_for(permission_template: permission_template)
      end

      # all PermissionTemplate release & visibility data attributes (if not blank or false)
      def attributes_for(permission_template:)
        {}.tap do |attrs|
          attrs['data-sharing'] = sharing?(permission_template: permission_template)
          # Either add "no-delay" (if immediate release) or a specific release date, but not both.
          if permission_template.release_no_delay?
            attrs['data-release-no-delay'] = true
          elsif permission_template.release_date.present?
            attrs['data-release-date'] = permission_template.release_date
          end
          attrs['data-release-before-date'] = true if permission_template.release_before_date?
          attrs['data-visibility'] = permission_template.visibility if permission_template.visibility.present?
        end
      end

      # Does the workflow for the currently selected permission template allow sharing?
      def sharing?(permission_template:)
        wf = workflow(permission_template: permission_template)
        return false unless wf
        wf.allows_access_grant?
      end

      def workflow(permission_template:)
        return unless permission_template.active_workflow
        Sipity::Workflow.find_by!(id: permission_template.active_workflow.id)
      end
  end
end
