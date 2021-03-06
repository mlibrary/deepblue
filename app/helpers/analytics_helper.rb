# frozen_string_literal: true

module AnalyticsHelper

  mattr_accessor :analytics_helper_debug_verbose,
                 default: ::Deepblue::AnalyticsIntegrationService.analytics_helper_debug_verbose

  # TODO: move this to email templates
  MONTHLY_ANALYTICS_REPORT_EMAIL_TEMPLATE = <<-END_OF_MONTHLY_ANALYTICS_REPORT_EMAIL_TEMPLATE
Your analytics report for the month of %{month}:

%{report_lines}

  END_OF_MONTHLY_ANALYTICS_REPORT_EMAIL_TEMPLATE

  MONTHLY_ANAYLYTICS_REPORT_EVENT_NAMES = [ "Hyrax::DataSetsController#show",
                                            "Hyrax::DataSetsController#zip_download",
                                            "Hyrax::DataSetsController#globus_download_redirect" ].freeze

  # TODO: move this config
  MONTHLY_EVENTS_REPORT_EVENT_NAME_TO_LABEL_MAP = { "Hyrax::DataSetsController#show" => "Visits",
                                                    "Hyrax::DataSetsController#zip_download" => "Zip Downloads",
                                                    "Hyrax::DataSetsController#globus_download_redirect" => "Globus Downloads" }.freeze

  # TODO: move this to email templates
  MONTHLY_EVENTS_REPORT_EMAIL_TEMPLATE = <<-END_OF_MONTHLY_EVENTS_REPORT_EMAIL_TEMPLATE
Your events report for the month of %{month}:

%{report_lines}

END_OF_MONTHLY_EVENTS_REPORT_EMAIL_TEMPLATE

  def self.chartkick?
    return false unless enable_local_analytics_ui?
    ::Deepblue::AnalyticsIntegrationService.enable_chartkick
  end

  def self.date_range_for_month_of( time: )
    beginning_of_month = time.beginning_of_month.beginning_of_day
    end_of_month = beginning_of_month.end_of_month.end_of_day
    date_range = beginning_of_month..end_of_month
    return date_range
  end

  def self.date_range_for_month_previous
    date_range_for_month_of( time: Time.now.beginning_of_month - 1.day )
  end

  def self.enable_local_analytics_ui?
    Flipflop.enable_local_analytics_ui?
  end

  def self.open_analytics_report_subscriptions?
    Flipflop.open_analytics_report_subscriptions?
  end

  def self.analytics_reports_admins_can_subscribe?
    ::Deepblue::AnalyticsIntegrationService.analytics_reports_admins_can_subscribe
  end

  def self.enable_analytics_works_reports_can_subscribe?
    ::Deepblue::AnalyticsIntegrationService.enable_analytics_works_reports_can_subscribe
  end

  def self.email_to_user( email )
    return nil unless email.present?
    user = User.find_by_user_key email
    user
  end

  def self.email_to_user_id( email )
    return nil unless email.present?
    user = User.find_by_user_key email
    return nil if user.blank?
    return user.id
  end

  def self.events_by_date( name:, cc_id: nil, data_name: nil, date_range: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "name=#{name}",
                                           "cc_id=#{cc_id}",
                                           "data_name=#{data_name}",
                                           "date_range=#{date_range}",
                                           "" ] if analytics_helper_debug_verbose

    if date_range.blank? && ::Deepblue::AnalyticsIntegrationService.hit_graph_day_window > 0
      date_range = ::Deepblue::AnalyticsIntegrationService.hit_graph_day_window.days.ago..(Date.today + 1.day)
    end
    rv = if cc_id.present?
           if date_range.blank?
             Ahoy::Event.where( name: name, cc_id: cc_id ).group_by_day( :time ).count
           else
             sql = Ahoy::Event.where( name: name, cc_id: cc_id, time: date_range ).group_by_day( :time ).to_sql
             ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                    ::Deepblue::LoggingHelper.called_from,
                                                    "sql=#{sql}",
                                                    "" ] if analytics_helper_debug_verbose
             Ahoy::Event.where( name: name,
                                cc_id: cc_id,
                                time: date_range ).group_by_day( :time ).count
           end
         elsif date_range.present?
           Ahoy::Event.where( name: name, time: date_range ).group_by_day( :time ).count
         else
           Ahoy::Event.where( name: name ).group_by_day( :time ).count
         end
    rv = { name: data_name, data: rv } if data_name.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "name=#{name}",
                                           "cc_id=#{cc_id}",
                                           "data_name=#{data_name}",
                                           "date_range=#{date_range}",
                                           "rv=#{rv}",
                                           "" ] if analytics_helper_debug_verbose
    return rv
  end

  def self.file_set_hits_by_date( controller_class:, cc_id: nil, date_range: nil )
    visits = events_by_date( name: "#{controller_class.name}#show",
                             cc_id: cc_id,
                             data_name: "visits",
                             date_range: date_range )
    downloads = events_by_date( name: "#{::Hyrax::DownloadsController.name}#show",
                                cc_id: cc_id,
                                data_name: "downloads",
                                date_range: date_range )
    [ visits, downloads ]
  end

  def self.hit_graph_admin?
    # 0 = none, 1 = admin, 2 = editor, 3 = everyone
    0 < ::Deepblue::AnalyticsIntegrationService.hit_graph_view_level
  end

  def self.hit_graph_editor?
    # 0 = none, 1 = admin, 2 = editor, 3 = everyone
    1 < ::Deepblue::AnalyticsIntegrationService.hit_graph_view_level
  end

  def self.hit_graph_everyone?
    # 0 = none, 1 = admin, 2 = editor, 3 = everyone
    2 < ::Deepblue::AnalyticsIntegrationService.hit_graph_view_level
  end

  def self.monthly_analytics_report( date_range: nil, debug_verbose: analytics_helper_debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "date_range=#{date_range}",
                                           "" ] if debug_verbose
    subscribers = monthly_analytics_report_subscribers( debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "subscribers=#{subscribers}",
                                           "" ] if debug_verbose
    return if subscribers.blank?
    date_range = date_range_for_month_of( time: Time.now.beginning_of_month - 1.day ) if date_range.blank?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "date_range=#{date_range}",
                                           "" ] if debug_verbose
    subscribers.each do |email|
      monthly_analytics_report_for( email: email, date_range: date_range, debug_verbose: debug_verbose )
    end
  end

  def self.monthly_analytics_report_for( email:, date_range:, debug_verbose: analytics_helper_debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "email=#{email}",
                                           "date_range=#{date_range}",
                                           "" ] if debug_verbose
    user = User.find_by_user_key email
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "user=#{user}",
                                           "" ] if debug_verbose
    return unless user.present?
    cc_ids = ::Deepblue::SearchService.run( {}, user ).map { |w| w['id'] }
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "cc_ids=#{cc_ids}",
                                           "" ] if debug_verbose
    event_names = MONTHLY_ANAYLYTICS_REPORT_EVENT_NAMES
    report_lines = []
    cc_ids.each do |cc_id|
      begin
        cc = ::PersistHelper.find cc_id
        report_lines << "#{cc.title.first} (#{cc_id}):"
        event_names.each do |event_name|
          condensed_event = Ahoy::CondensedEvent.find_by( name: event_name,
                                                          cc_id: cc_id,
                                                          date_begin: date_range.first,
                                                          date_end: date_range.last )
          report_lines << monthly_analytics_report_line_for( name: event_name,
                                                             condensed_event: condensed_event,
                                                             debug_verbose: debug_verbose )
        end
      rescue Ldp::Gone
        monthly_events_report_unsubscribe( user: user, cc_id: cc_id ) # TODO
      end
    end
    monthly_analytics_report_send_email( date_range: date_range,
                                         email: email,
                                         report_lines: report_lines,
                                         debug_verbose: debug_verbose )
  end

  def self.monthly_analytics_report_line_for( name:, condensed_event:, debug_verbose: analytics_helper_debug_verbose )
    count = 0
    label = MONTHLY_EVENTS_REPORT_EVENT_NAME_TO_LABEL_MAP[name]
    if condensed_event.present?
      # condensed_event is of the form { "date label 1" => count, "date label 2" => count ... }
      date_map = condensed_event.condensed_event
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "name=#{name}",
                                             "date_map=#{date_map}",
                                             "" ] if debug_verbose
      date_map.each do |_date_label,date_count|
        count = count + date_count.to_i
      end
    end
    return "  #{label}: #{count}"
  end

  def self.monthly_analytics_report_send_email( date_range:,
                                                email:,
                                                report_lines:,
                                                content_type: nil,
                                                debug_verbose: analytics_helper_debug_verbose )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "date_range=#{date_range}",
                                           "email=#{email}",
                                           "report_lines=#{report_lines}",
                                           "content_type=#{content_type}",
                                           "" ] if debug_verbose
    body = MONTHLY_ANALYTICS_REPORT_EMAIL_TEMPLATE.dup
    month = ::Deepblue::EmailHelper.to_month( date_range.first )
    body.gsub!( /\%\{month\}/, month )
    body.gsub!( /\%\{report_lines\}/, report_lines.join("\n") )
    subject = "Analytics Report for Works during #{month}" # TODO: i18n
    email_sent = ::Deepblue::EmailHelper.send_email( to: email,
                                                     subject: subject,
                                                     body: body,
                                                     content_type: content_type )
    ::Deepblue::EmailHelper.log( class_name: "AnalyticsHelper",
                                 current_user: nil,
                                 event: "monthly analytics report",
                                 event_note: "Month: ${month}",
                                 id: "N/A",
                                 to: email,
                                 subject: subject,
                                 body: body,
                                 email_sent: email_sent )
  end

  def self.monthly_analytics_report_subscribed?( user: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "user.id=#{user.id}",
                                           "user.email=#{user.email}",
                                           "" ] if analytics_helper_debug_verbose
    record = EmailSubscription.find_by( subscription_name: monthly_analytics_report_subscription_id, user_id: user.id )
    record.present?
  end

  def self.monthly_analytics_report_subscribe( user: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "user.id=#{user.id}",
                                           "user.email=#{user.email}",
                                           "" ] if analytics_helper_debug_verbose
    return unless user.present?
    record = EmailSubscription.find_or_create_by( subscription_name: monthly_analytics_report_subscription_id,
                                                  user_id: user.id )
    record.email = user.email
    record.save
  end

  def self.monthly_analytics_report_subscribers( debug_verbose: analytics_helper_debug_verbose )
    ::Deepblue::EmailSubscriptionService.subscribers_for( subscription_service_id: monthly_analytics_report_subscription_id,
                                                          include_parameters: false,
                                                          debug_verbose: debug_verbose )
  end

  def self.monthly_analytics_report_subscription_id
    ::Deepblue::AnalyticsIntegrationService.monthly_analytics_report_subscription_id
  end

  def self.monthly_analytics_report_unsubscribe( user: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "user.id=#{user.id}",
                                           "user.email=#{user.email}",
                                           "" ] if analytics_helper_debug_verbose
    return if user.blank?
    record = EmailSubscription.find_by( subscription_name: monthly_analytics_report_subscription_id,
                                                  user_id: user.id )
    return unless record.present?
    record.delete
  end

  def self.monthly_events_report( date_range: nil, debug_verbose: analytics_helper_debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "date_range=#{date_range}",
                                           "" ] if debug_verbose
    subscribers = monthly_events_report_subscribers
    return if subscribers.blank?
    date_range = date_range_for_month_of( time: Time.now.beginning_of_month - 1.day ) if date_range.blank?
    subscribers.each do |email_params_pair|
      email = email_params_pair[0]
      params = email_params_pair[1]
      next if params.blank?
      monthly_events_report_for( email: email, params: params, date_range: date_range, debug_verbose: debug_verbose )
    end
  end

  def self.monthly_events_report_for( email:, params:, date_range:, debug_verbose: analytics_helper_debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "email=#{email}",
                                           "params=#{params}",
                                           "date_range=#{date_range}",
                                           "" ] if debug_verbose
    # params is of the form: { id1 => [event_name1,event_name2 ...], id2 => [event_name1,event_name2 ...] ... }
    report_lines = []
    params.each do |cc_id,event_names|
      begin
        cc = ::PersistHelper.find cc_id
        report_lines << "#{cc.title.first} (#{cc_id}):"
        event_names.each do |event_name|
          condensed_event = Ahoy::CondensedEvent.find_by( name: event_name,
                                                          cc_id: cc_id,
                                                          date_begin: date_range.first,
                                                          date_end: date_range.last )
          report_lines << monthly_events_report_line_for( name: event_name, condensed_event: condensed_event )
        end
      rescue Ldp::Gone
        monthly_events_report_unsubscribe( user: email_to_user( email ), cc_id: cc_id )
      end
    end
    monthly_events_report_send_email( date_range: date_range,
                                      email: email,
                                      report_lines: report_lines,
                                      debug_verbose: debug_verbose )
  end

  def self.monthly_events_report_line_for( name:, condensed_event: )
    count = 0
    label = MONTHLY_EVENTS_REPORT_EVENT_NAME_TO_LABEL_MAP[name]
    if condensed_event.present?
      # condensed_event is of the form { "date label 1" => count, "date label 2" => count ... }
      date_map = condensed_event.condensed_event
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "name=#{name}",
                                             "date_map=#{date_map}",
                                             "" ] if analytics_helper_debug_verbose
      date_map.each do |_date_label,date_count|
        count = count + date_count.to_i
      end
    end
    return "  #{label}: #{count}"
  end

  def self.monthly_events_report_send_email( date_range:,
                                             email:,
                                             report_lines:,
                                             content_type: nil,
                                             debug_verbose: analytics_helper_debug_verbose )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "date_range=#{date_range}",
                                           "email=#{email}",
                                           "report_lines=#{report_lines}",
                                           "content_type=#{content_type}",
                                           "" ] if debug_verbose
    body = MONTHLY_EVENTS_REPORT_EMAIL_TEMPLATE.dup
    month = ::Deepblue::EmailHelper.to_month( date_range.first )
    body.gsub!( /\%\{month\}/, month )
    body.gsub!( /\%\{report_lines\}/, report_lines.join("\n") )
    subject = "Events Report for Works during #{month}" # TODO: i18n
    email_sent = ::Deepblue::EmailHelper.send_email( to: email,
                                                     subject: subject,
                                                     body: body,
                                                     content_type: content_type )
    ::Deepblue::EmailHelper.log( class_name: "AnalyticsHelper",
                                 current_user: nil,
                                 event: "monthly analytics report",
                                 event_note: "Month: ${month}",
                                 id: "N/A",
                                 to: email,
                                 subject: subject,
                                 body: body,
                                 email_sent: email_sent )
  end

  def self.monthly_events_report_subscribe( user:, cc_id:, event_names: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "user.id=#{user.id}",
                                           "user.email=#{user.email}",
                                           "cc_id=#{cc_id}",
                                           "event_names=#{event_names}",
                                           "" ] if analytics_helper_debug_verbose
    return unless user.present?
    record = EmailSubscription.find_or_create_by( subscription_name: monthly_events_report_subscription_id,
                                                  user_id: user.id )
    sub_params = record.subscription_parameters
    if sub_params.blank?
      sub_params = { cc_id => event_names }
    else
      sub_params[cc_id] = event_names
    end
    record.subscription_parameters = sub_params
    record.email = user.email
    record.save
  end

  # convenience method, TODO: move to DataSetsController
  def self.monthly_events_report_subscribe_data_set( user:, cc_id: )
    monthly_events_report_subscribe( user: user,
                                     cc_id: cc_id,
                                     event_names: [ "Hyrax::DataSetsController#show",
                                                    "Hyrax::DataSetsController#zip_download",
                                                    "Hyrax::DataSetsController#globus_download_redirect" ] )
  end

  # convenience method, TODO: move to DataSetsController
  def self.monthly_events_report_unsubscribe_data_set( user:, cc_id: )
    monthly_events_report_unsubscribe( user: user, cc_id: cc_id )
  end

  def self.monthly_events_report_subscribers
    ::Deepblue::EmailSubscriptionService.subscribers_for( subscription_service_id: monthly_events_report_subscription_id,
                                                          include_parameters: true )
  end

  def self.monthly_events_report_subscription_id
    ::Deepblue::AnalyticsIntegrationService.monthly_events_report_subscription_id
  end

  def self.monthly_events_report_subscribed?( user:, cc_id: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "user.id=#{user.id}",
                                           "user.email=#{user.email}",
                                           "cc_id=#{cc_id}",
                                           "" ] if analytics_helper_debug_verbose
    record = EmailSubscription.find_by( subscription_name: monthly_events_report_subscription_id, user_id: user.id )
    return false unless record.present?
    sub_params = record.subscription_parameters
    return false if sub_params.blank?
    rv = sub_params.has_key? cc_id
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "user.id=#{user.id}",
                                           "user.email=#{user.email}",
                                           "cc_id=#{cc_id}",
                                           "rv=#{rv}",
                                           "" ] if analytics_helper_debug_verbose
    return rv
  end

  def self.monthly_events_report_unsubscribe( user:, cc_id: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "user.id=#{user.id}",
                                           "user.email=#{user.email}",
                                           "cc_id=#{cc_id}",
                                           "event_names=#{event_names}",
                                           "" ] if analytics_helper_debug_verbose
    return if user.blank?
    record = EmailSubscription.find_or_create_by( subscription_name: monthly_events_report_subscription_id,
                                                  user_id: user.id )
    return unless record.present?
    sub_params = record.subscription_parameters
    if sub_params.blank?
      record.delete
      return
    end
    return unless sub_params.has_key? cc_id
    sub_params.delete cc_id
    if sub_params.blank?
      record.delete
      return
    end
    record.subscription_parameters = sub_params
    record.email = user.email
    record.save
  end

  def self.page_hits_by_date( controller_class:, cc_id: nil, date_range: nil )
    events_by_date( name: "#{controller_class.name}#show", cc_id: cc_id, date_range: date_range )
  end

  def self.show_hit_graph?( current_ability, presenter: nil )
    return false unless enable_local_analytics_ui?
    # 0 = none, 1 = admin, 2 = editor, 3 = everyone
    return false if presenter && presenter.respond_to?( :single_use_show? ) && presenter.single_use_show?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "::Deepblue::AnalyticsIntegrationService.hit_graph_view_level=#{::Deepblue::AnalyticsIntegrationService.hit_graph_view_level}",
                                           "current_ability.admin?=#{current_ability.admin?}",
                                           "presenter.respond_to? :can_subscribe_to_analytics_reports?=#{presenter.respond_to? :can_subscribe_to_analytics_reports?}",
                                           "presenter.can_subscribe_to_analytics_reports?=#{presenter.respond_to?(:can_subscribe_to_analytics_reports?) ? presenter.can_subscribe_to_analytics_reports? : ''}",
                                           "" ] if analytics_helper_debug_verbose
    case ::Deepblue::AnalyticsIntegrationService.hit_graph_view_level
    when 0
      false
    when 1
      current_ability.admin?
    when 2
      return true if current_ability.admin?
      return presenter.can_subscribe_to_analytics_reports? if presenter.respond_to? :can_subscribe_to_analytics_reports?
      # return current_ability.editor? if current_ability.respond_to? :editor?
      false
    when 3
      true
    else
      false
    end
  end

  def self.update_current_month_condensed_events
    # will there be an issue with daily savings time?
    beginning_of_month = Time.now.beginning_of_month.beginning_of_day
    end_of_month = beginning_of_month.end_of_month.end_of_day
    date_range = beginning_of_month..end_of_month
    update_condensed_events_for( date_range: date_range )
  end

  def self.update_condensed_events_for( date_range: )
    name_cc_ids = Ahoy::Event.select( :name, :cc_id ).where( time: date_range ).distinct.pluck( :name, :cc_id )
    name_cc_ids.each do |name_cc_id|
      name = name_cc_id[0]
      cc_id = name_cc_id[1]
      condensed_data = Ahoy::Event.where( name: name, cc_id: cc_id, time: date_range ).group_by_day( :time ).count
      condensed_event = Ahoy::CondensedEvent.find_by( name: name,
                                                      cc_id: cc_id,
                                                      date_begin: date_range.first,
                                                      date_end: date_range.last )
      if condensed_event.blank?
        condensed_event = Ahoy::CondensedEvent.new( name: name,
                                                    cc_id: cc_id,
                                                    date_begin: date_range.first,
                                                    date_end: date_range.last )
      end
      condensed_event.condensed_event = condensed_data
      condensed_event.save
    end
  end

  def self.work_hits_by_date( controller_class:, cc_id: nil, date_range: nil )
    visits = events_by_date( name: "#{controller_class.name}#show",
                             cc_id: cc_id,
                             data_name: "visits",
                             date_range: date_range )
    zip = events_by_date( name: "#{controller_class.name}#zip_download",
                          cc_id: cc_id,
                          data_name: "zip",
                          date_range: date_range )
    globus = events_by_date( name: "#{controller_class.name}#globus_download_redirect",
                             cc_id: cc_id,
                             data_name: "globus",
                             date_range: date_range )
    [ visits, zip, globus ]
  end

end
