# frozen_string_literal: true

module Deepblue

  module SingleUseLinkControllerBehavior

    SINGLE_USE_LINK_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.single_use_link_controller_behavior_debug_verbose

    def single_use_link_obj( link_id: )
      @single_use_link_obj ||= find_single_use_link_obj( link_id: link_id )
    end

    private

      def find_single_use_link_obj( link_id: )
        return '' if link_id.blank?
        return SingleUseLink.find_by_downloadKey!( link_id )
      rescue ActiveRecord::RecordNotFound => _ignore
        return '' # blank, so we only try looking it up once
      end


  end

end
