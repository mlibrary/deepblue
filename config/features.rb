# frozen_string_literal: true

Flipflop.configure do

  group :orcid do

    feature :hyrax_orcid,
            default: true,
            description: "Enable Hyrax ORCID functionality."

    feature :strict_orcid,
            default: true,
            description: "Enable ORCID functionality."

  end

  group :deep_blue_data do

    feature :only_use_data_set_work_type,
            default: true,
            description: "Only give users ability to create Data Set Work Type"

    feature :limit_browse_options,
            default: true,
            description: "Limit the users' browse options"

    feature :dir_upload,
            default: false,
            description: "Allow user to upload files for work from a directory."


    feature :enable_local_analytics_ui,
            default: false,
            # reference to I18n does not work from here:
            # description: I18n.t( "flipflop.feature_description.enable_local_analytics_ui" )
            description: "Enable local analytics access through the UI."

    feature :open_analytics_report_subscriptions,
            default: false,
            description: "Depositors can subscribe to analytic reports."

    feature :disable_desposits_and_edits,
            default: false,
            description: "Disable all deposits and edits to the system."

    feature :display_subheader,
            default: true,
            description: "Display a subheader below the standard header."

  end

  group :masthead_banner_announcements do

    feature :display_masthead_banner_standard,
            default: false,
            description: "Default masthead banner"

    feature :display_masthead_banner_maintenance,
            default: false,
            description: "Maintenance masthead banner"

    feature :display_masthead_banner_slow,
            default: false,
            description: "Slow masthead banner"

    feature :display_masthead_banner_outage,
            default: false,
            description: "Outage masthead banner"

  end


end
