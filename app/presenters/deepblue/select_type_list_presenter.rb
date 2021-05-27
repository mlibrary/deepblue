
module Deepblue

  # Presents the list of work type options that a user may choose from when deciding to
  # create a new work
  class SelectTypeListPresenter < ::Hyrax::SelectTypeListPresenter

    mattr_accessor :deepblue_select_type_list_presenter_debug_verbose, default: false

    # @param current_user [User]
    def initialize(current_user)
      super
    end

    def analytics_subscribed?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user.id=#{@current_user.id}",
                                             "" ] if deepblue_select_type_list_presenter_debug_verbose
      ::AnalyticsHelper::monthly_analytics_report_subscribed?( user_id: @current_user.id )
    end

    def can_subscribe_to_analytics_reports?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if deepblue_select_type_list_presenter_debug_verbose
      return false unless AnalyticsHelper.enable_local_analytics_ui?
      true
    end

  end

end
