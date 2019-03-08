# don't freeze, it causes errors

require File.join(Gem::Specification.find_by_name("hydra-access-controls").full_gem_path, "app/models/concerns/hydra/access_controls/embargoable.rb")

module Hydra

  module AccessControls

    # monkey patch Embargoable#deactivate_embargo!
    module Embargoable
      alias_method :monkey_deactivate_embargo!, :deactivate_embargo!
      alias_method :monkey_deactivate_lease!, :deactivate_lease!

      # Deactivates the embargo and logs a message to the embargo object.
      # Marks this record as dirty so that it will get reindexed.
      def deactivate_embargo!
        return if embargo.nil?
        # embargo.deactivate! whipes out work.visibility_after_embargo before it can be applied, so save it and apply it
        vis_after = visibility_after_embargo
        vis_after = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED if vis_after.nil?
        # Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                      Deepblue::LoggingHelper.called_from,
        #                                      "before",
        #                                      "vis_after=#{vis_after}",
        #                                      "id=#{id}",
        #                                      "embargo_release_date=#{embargo_release_date}",
        #                                      "visibility=#{visibility}",
        #                                      "visibility_during_embargo=#{visibility_during_embargo}",
        #                                      "visibility_after_embargo=#{visibility_after_embargo}" ]
        embargo.deactivate!
        # Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                      Deepblue::LoggingHelper.called_from,
        #                                      "after",
        #                                      "id=#{id}",
        #                                      "embargo_release_date=#{embargo_release_date}",
        #                                      "visibility=#{visibility}",
        #                                      "visibility_during_embargo=#{visibility_during_embargo}",
        #                                      "visibility_after_embargo=#{visibility_after_embargo}" ]
        self.visibility = vis_after
        visibility_will_change!
      end

      def deactivate_lease!
        return if lease.nil?
        # lease.deactivate! whipes out work.visibility_after_lease before it can be applied, so save it and apply
        vis_after = visibility_after_lease
        vis_after = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE if vis_after.nil?
        lease.deactivate!
        self.visibility = vis_after
        visibility_will_change!
      end

    end

  end

end
