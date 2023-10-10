# frozen_string_literal: true

module AnalyticsHelper

  mattr_accessor :analytics_helper_debug_verbose,
                 default: ::Deepblue::AnalyticsIntegrationService.analytics_helper_debug_verbose

  mattr_accessor :max_visit_filter_count,
                 default: ::Deepblue::AnalyticsIntegrationService.max_visit_filter_count

  mattr_accessor :max_visits_per_month_filter,
                 default: ::Deepblue::AnalyticsIntegrationService.max_visits_per_month_filter

  mattr_accessor :skip_admin_events, # default: false
                 default: ::Deepblue::AnalyticsIntegrationService.skip_admin_events

  mattr_accessor :store_zero_total_downloads,
                 default: ::Deepblue::AnalyticsIntegrationService.store_zero_total_downloads
  BEGINNING_OF_TIME = Time.utc(1972,1,1).freeze
  END_OF_TIME       = (BEGINNING_OF_TIME + 1000.year).freeze
  DATE_RANGE_ALL    = BEGINNING_OF_TIME..END_OF_TIME

  DEFAULT_DATE_RANGE_FILTER = nil
  DEFAULT_FORCED            = false
  DEFAULT_CLEAN_WORK_EVENTS = true
  DEFAULT_ONLY_PUBLISHED    = true

  FILE_SET_CONDENSED           = "FileSetCondensed".freeze
  FILE_SET_DWNLDS_PER_MONTH    = "FileSetDownloadsPerMonth".freeze
  FILE_SET_DWNLDS_TO_DATE      = "FileSetDownloadsToDate".freeze
  FILE_SET_DWNLDS_ALL = [ FILE_SET_DWNLDS_PER_MONTH,
                          FILE_SET_DWNLDS_TO_DATE ]

  WORK_CONDENSED               = "WorkCondensed".freeze
  WORK_FILE_DWNLDS_PER_MONTH   = "WorkFileDownloadsPerMonth".freeze
  WORK_FILE_DWNLDS_TO_DATE     = "WorkFileDownloadsToDate".freeze
  WORK_GLOBUS_DWNLDS_PER_MONTH = "WorkGlobusDownloadsPerMonth".freeze
  WORK_GLOBUS_DWNLDS_TO_DATE   = "WorkGlobusDownloadsToDate".freeze
  WORK_ZIP_DWNLDS_PER_MONTH    = "WorkZipDownloadsPerMonth".freeze
  WORK_ZIP_DWNLDS_TO_DATE      = "WorkZipDownloadsToDate".freeze
  WORK_DWNLDS_ALL = [ WORK_FILE_DWNLDS_PER_MONTH,
                      WORK_FILE_DWNLDS_TO_DATE,
                      WORK_GLOBUS_DWNLDS_PER_MONTH,
                      WORK_GLOBUS_DWNLDS_TO_DATE,
                      WORK_ZIP_DWNLDS_PER_MONTH,
                      WORK_ZIP_DWNLDS_TO_DATE ]

  DOWNLOAD_EVENT          = "Hyrax::DownloadsController#show".freeze
  WORK_GLOBUS_EVENT       = "Hyrax::DataSetsController#globus_download_redirect".freeze
  WORK_SHOW_EVENT         = "Hyrax::DataSetsController#show".freeze
  WORK_ZIP_DOWNLOAD_EVENT = "Hyrax::DataSetsController#zip_download".freeze

  MSG_HANDLER_DEBUG_ONLY = ::Deepblue::MessageHandlerDebugOnly.new( debug_verbose: ->() { analytics_helper_debug_verbose } ).freeze

  HIGH_TRAFFIC = -1.freeze
  HIGH_TRAFFIC_IP = 'HighTrafficIP'.freeze

  # TODO: move this to email templates
  MONTHLY_ANALYTICS_REPORT_EMAIL_TEMPLATE = <<-END_OF_MONTHLY_ANALYTICS_REPORT_EMAIL_TEMPLATE
Your analytics report for the month of %{month}:

%{report_lines}

END_OF_MONTHLY_ANALYTICS_REPORT_EMAIL_TEMPLATE

  MONTHLY_ANAYLYTICS_REPORT_EVENT_NAMES = [ WORK_SHOW_EVENT,
                                            WORK_ZIP_DOWNLOAD_EVENT,
                                            WORK_GLOBUS_EVENT ].freeze

  # TODO: move this config
  MONTHLY_EVENTS_REPORT_EVENT_NAME_TO_LABEL_MAP = { WORK_SHOW_EVENT => "Visits",
                                                    WORK_ZIP_DOWNLOAD_EVENT => "Zip Downloads",
                                                    WORK_GLOBUS_EVENT => "Globus Downloads" }.freeze

  # TODO: move this to email templates
  MONTHLY_EVENTS_REPORT_EMAIL_TEMPLATE = <<-END_OF_MONTHLY_EVENTS_REPORT_EMAIL_TEMPLATE
Your events report for the month of %{month}:

%{report_lines}

END_OF_MONTHLY_EVENTS_REPORT_EMAIL_TEMPLATE

  def self.analytics_reports_admins_can_subscribe?
    ::Deepblue::AnalyticsIntegrationService.analytics_reports_admins_can_subscribe
  end

  def self.chartkick?
    return false unless enable_local_analytics_ui?
    ::Deepblue::AnalyticsIntegrationService.enable_chartkick
  end

  def self.condensed_events_to_csv( file_path:, truncate_dates: true, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    file_path = ::Deepblue::ReportHelper.expand_path_partials( file_path, task: 'condensed_events' )
    file_path = File.absolute_path file_path
    return file_path unless msg_handler.msg_error_unless?( Dir.exist?(File.dirname(file_path)),
                                                 msg: "Parent directory not found: '#{file_path}'"  )
    CSV.open( file_path, 'w', {:force_quotes=>true} ) do |csv|
      condensed_events_to_csv_header_row( csv )
      msg_handler.msg_verbose {"Writing #{::Ahoy::CondensedEvent.all.size} condensed events to #{file_path}"}
      ::Ahoy::CondensedEvent.all.each do |condensed_event|
        condensed_events_to_csv_row( csv, condensed_event, truncate_dates: truncate_dates, msg_handler: msg_handler )
      end
    end
    return file_path
  end

  def self.condensed_events_to_csv_header_row( csv )
    csv << %w[name cc_id date_begin date_end condensed_event created_at updated_at]
  end

  def self.condensed_events_to_csv_row( csv, condensed_event, truncate_dates:, msg_handler: nil )
    date_begin = condensed_event.date_begin
    date_end = condensed_event.date_end
    date_begin = date_begin.strftime('%Y/%m/%d') if truncate_dates
    date_end = date_end.strftime('%Y/%m/%d') if truncate_dates
    csv << [ condensed_event.name,
             condensed_event.cc_id,
             date_begin,
             date_end,
             condensed_event.condensed_event,
             condensed_event.created_at,
             condensed_event.updated_at ]
  end

  # def self.compute_ip_count_for_object( event:, cc_id:, visit_id:, date_range_filter:, msg_handler: nil )
  #   msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
  #   return 0 if date_range_filter == date_range_all
  #   debug_verbose = analytics_helper_debug_verbose
  #   msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
  #                            ::Deepblue::LoggingHelper.called_from,
  #                            "event=#{event}",
  #                            "cc_id=#{cc_id}",
  #                            "visit_id=#{visit_id}",
  #                            "date_range_filter=#{date_range_readable(date_range_filter)}",
  #                            "" ] if debug_verbose
  #   # Get all the events for this time period and this id
  #   events = Ahoy::Event.where( name: event,  cc_id: cc_id, time: date_range_filter )
  #   msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
  #                            ::Deepblue::LoggingHelper.called_from,
  #                            "events&.size=#{events&.size}",
  #                            "" ] if debug_verbose
  #   return 0 if events.blank?
  #
  #   # Get the visit information for this specific event
  #   visit_to_test = Ahoy::Visit.where( id: visit_id )
  #   msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
  #                            ::Deepblue::LoggingHelper.called_from,
  #                            "visit_to_test&.size=#{visit_to_test&.size}",
  #                            "" ] if debug_verbose
  #   return 0 if visit_to_test.blank?
  #   visit_to_test_first_ip = visit_to_test.first.ip
  #   records = Ahoy::CondensedEvent.where( name: HIGH_TRAFFIC_IP, cc_id: visit_to_test_first_ip )
  #   return max_visits_per_month_filter if records.present?
  #   msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
  #                            ::Deepblue::LoggingHelper.called_from,
  #                            "visit_to_test_first_ip=#{visit_to_test_first_ip}",
  #                            "" ] if debug_verbose
  #   count = 0
  #   events.each do |e|
  #     break if count > max_visits_per_month_filter
  #     next if download_event_skip_file?( e, msg_handler: msg_handler )
  #     if e.visit_id == visit_id
  #       count += 1
  #       next
  #     end
  #     v = Ahoy::Visit.where( id: e.visit_id )
  #     next if v.blank?
  #     count += 1 if v.first.ip.eql? visit_to_test_first_ip
  #   end
  #   Ahoy::CondensedEvent.new( name: HIGH_TRAFFIC_IP, cc_id: visit_to_test_first_ip ).new.save! if count > max_visits_per_month_filter
  #   return count
  # end

  def self.date_range_all
    return DATE_RANGE_ALL
    # can be changed for localhost
  end

  def self.date_range_for_month_of( time: )
    if time.respond_to? :getgm
      # puts "converting time to GMT"
      time = time.getgm
    end
    beginning_of_month = time.beginning_of_month.beginning_of_day
    end_of_month = beginning_of_month.end_of_month.end_of_day
    date_range = beginning_of_month..end_of_month
    return date_range
  end

  def self.date_range_for_month_previous
    date_range_for_month_of( time: gmtnow.beginning_of_month - 1.day )
  end

  def self.date_range_from( condensed_event_record )
    date_range = condensed_event_record.date_begin..condensed_event_record.date_end
    return date_range
  end

  def self.date_range_expand( date_range_first, date_range_second )
    date_range = date_range_first.first..date_range_second.last
    return date_range
  end

  def self.date_range_readable( date_range )
    return 'EMPTY' if date_range.blank?
    first = date_range.first
    last = date_range.last
    first ||= 'EMPTY'
    last ||= 'EMPTY'
    first = first.strftime('%Y/%m/%d') if first.respond_to? :strftime
    last = last.strftime('%Y/%m/%d') if last.respond_to? :strftime
    return "#{first}-#{last}"
  end

  def self.date_range_since_start
    previous_month = gmtnow.beginning_of_month - 1.day
    end_of_previous_month = previous_month.end_of_month.end_of_day
    beginning_of_time = BEGINNING_OF_TIME
    date_range = beginning_of_time..end_of_previous_month
    # date_range = BEGINNING_OF_TIME..END_OF_TIME # For testing on local machine
    return date_range
  end

  def self.delete_condensed_event_monthly( name:, cc_id:, month:, msg_handler: nil )
    record = Ahoy::CondensedEvent.find_by( name: name, cc_id: cc_id, date_begin: month.first, date_end: month.last )
    return if record.nil?
    record.delete
  end

  def self.delete_all_condensed_events_total_downloads_zero( msg_handler: nil )
    FILE_SET_DWNLDS_ALL.each { |name| delete_condensed_events_total_downloads_zero( name: name, msg_handler: msg_handler ) }
    WORK_DWNLDS_ALL.each { |name| delete_condensed_events_total_downloads_zero( name: name, msg_handler: msg_handler ) }
  end

  def self.delete_condensed_events_total_downloads_zero( name:, cc_id: nil, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    if cc_id.blank?
      records = Ahoy::CondensedEvent.where( name: name )
    else
      records = Ahoy::CondensedEvent.where( name: name, cc_id: cc_id )
    end
    records.each do |record|
      if total_downloads_zero?( record )
        # msg_handler.msg_verbose "delete record: #{record.inspect}"
        record.delete
      end
    end
  end

  def self.ce_inspect( record )
    "name: #{name}, cc_id: #{cc_id}, ..."
  end

  def self.download_event_skip_file?( event, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    return true if event.properties['file'] == 'thumbnail'
    if skip_admin_events && user_is_admin( user_id: event.user_id )
      # msg_handler.msg_verbose "Skipping because #{event.user_id} is an admin"
      return true
    end
    return false
  end

  def self.download_event_skip_non_file?( record, msg_handler )
    return false unless skip_admin_events
    user_is_admin( user_id: record.user_id )
  end

  def self.download_file_set_monthly_cnt( id:, date_range: nil )
    date_range = truncate_date(date_range.first)..truncate_date(date_range.last) unless date_range.nil?

    file_download_cnt = monthly_hits_by_date_and_name( id: id, name: FILE_SET_DWNLDS_PER_MONTH, date_range: date_range )

    return file_download_cnt
  end

  def self.download_todate_cnt( id:, date_range: nil )
    zip_download_cnt = monthly_hits_by_date_and_name( id: id, name: WORK_ZIP_DWNLDS_TO_DATE, date_range: date_range )
    globus_download_cnt = monthly_hits_by_date_and_name( id: id, name: WORK_GLOBUS_DWNLDS_TO_DATE, date_range: date_range )
    file_download_cnt = monthly_hits_by_date_and_name( id: id, name: WORK_FILE_DWNLDS_TO_DATE, date_range: date_range )

    return zip_download_cnt + globus_download_cnt + file_download_cnt
  end

  def self.download_monthly_cnt ( work_id:, date_range: nil )
    download_work_monthly_cnt( id: work_id, date_range: date_range )
  end

  def self.download_work_monthly_cnt( id:, date_range: nil )
    date_range = truncate_date(date_range.first)..truncate_date(date_range.last) unless date_range.nil?

    zip_download_cnt = monthly_hits_by_date_and_name( id: id, name: WORK_ZIP_DWNLDS_PER_MONTH, date_range: date_range )
    globus_download_cnt = monthly_hits_by_date_and_name( id: id, name: WORK_GLOBUS_DWNLDS_PER_MONTH, date_range: date_range )
    file_download_cnt = monthly_hits_by_date_and_name( id: id, name: WORK_FILE_DWNLDS_PER_MONTH, date_range: date_range )

    return zip_download_cnt + globus_download_cnt + file_download_cnt
  end

  # This is just needed at the time the stats are setup from rails console
  def self.drop_condensed_event_downloads( all: false, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    drop_condensed_event_guards( msg_handler: msg_handler )
    if all
      drop_condensed_events( event: FILE_SET_DWNLDS_PER_MONTH, msg_handler: msg_handler )
      drop_condensed_events( event: FILE_SET_DWNLDS_TO_DATE, msg_handler: msg_handler )
      drop_condensed_events( event: WORK_FILE_DWNLDS_PER_MONTH, msg_handler: msg_handler )
      drop_condensed_events( event: WORK_FILE_DWNLDS_TO_DATE, msg_handler: msg_handler )
      drop_condensed_events( event: WORK_ZIP_DWNLDS_PER_MONTH, msg_handler: msg_handler )
      drop_condensed_events( event: WORK_ZIP_DWNLDS_TO_DATE, msg_handler: msg_handler )
      drop_condensed_events( event: WORK_GLOBUS_DWNLDS_PER_MONTH, msg_handler: msg_handler )
      drop_condensed_events( event: WORK_GLOBUS_DWNLDS_TO_DATE, msg_handler: msg_handler )
    end
  end

  # This is just needed at the time the stats are setup from rails console
  def self.drop_condensed_event_guards( msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    drop_condensed_events( event: FILE_SET_CONDENSED, msg_handler: msg_handler )
    drop_condensed_events( event: WORK_CONDENSED, msg_handler: msg_handler )
  end

  # This is just needed at the time the stats are setup from rails console
  def self.drop_high_traffic_ip_condensed_events( msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    drop_condensed_events( event: HIGH_TRAFFIC_IP, msg_handler: msg_handler )
  end

  # This is just needed at the time the stats are setup from rails console
  def self.drop_condensed_event_downloads_for_work( work:, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    id = work.id
    drop_condensed_events_by_id( cc_id: id, event: WORK_FILE_DWNLDS_PER_MONTH, msg_handler: msg_handler )
    drop_condensed_events_by_id( cc_id: id, event: WORK_FILE_DWNLDS_TO_DATE, msg_handler: msg_handler )
    drop_condensed_events_by_id( cc_id: id, event: WORK_ZIP_DWNLDS_PER_MONTH, msg_handler: msg_handler )
    drop_condensed_events_by_id( cc_id: id, event: WORK_ZIP_DWNLDS_TO_DATE, msg_handler: msg_handler )
    drop_condensed_events_by_id( cc_id: id, event: WORK_GLOBUS_DWNLDS_PER_MONTH, msg_handler: msg_handler )
    drop_condensed_events_by_id( cc_id: id, event: WORK_GLOBUS_DWNLDS_TO_DATE, msg_handler: msg_handler )
    work.file_set_ids.each do |fid|
      drop_condensed_events_by_id( cc_id: fid, event: FILE_SET_DWNLDS_PER_MONTH, msg_handler: msg_handler )
      drop_condensed_events_by_id( cc_id: fid, event: FILE_SET_DWNLDS_TO_DATE, msg_handler: msg_handler )
    end
  end

  def self.drop_condensed_events( event:, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    events = Ahoy::CondensedEvent.where( name: event )
    event_count = events.size
    msg_handler.msg_verbose "Drop #{event_count} records with name: #{event}."
    events.delete_all # as vs. destroy_all
    return event_count
  end

  def self.drop_condensed_events_by_id( cc_id:, event:, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    verbose = false
    events = Ahoy::CondensedEvent.where( name: event, cc_id: cc_id )
    event_count = events.size
    msg_handler.msg_verbose {"Drop #{event_count} records for cc_id: #{cc_id} with name: #{event}."} if verbose
    events.delete_all # as vs. destroy_all
    return event_count
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

  def self.enable_analytics_works_reports_can_subscribe?
    ::Deepblue::AnalyticsIntegrationService.enable_analytics_works_reports_can_subscribe
  end

  def self.enable_local_analytics_ui?
    Flipflop.enable_local_analytics_ui?
  end

  def self.event_records_for( event:, cc_id:, date_range:, per_month:, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    records = Ahoy::Event.where( name: event, cc_id: cc_id, time: date_range )
    msg_handler.msg_verbose "#{records.size} #{event} found for #{cc_id} in #{date_range_readable date_range}"
    return records if per_month.blank?
    month_per_month_record_map = {}
    records.each do |record|
      month = date_range_for_month_of( time: record.time )
      next if month_per_month_record_map[month.first].present?
      per_month_record = Ahoy::CondensedEvent.find_or_create_by( name: per_month,
                                                                 cc_id: cc_id,
                                                                 date_begin: month.first,
                                                                 date_end: month.last )
      msg_handler.msg_verbose "Create #{per_month_record.name} #{per_month_record.cc_id} for #{date_range_readable month}"
      month_per_month_record_map[month.first] = per_month_record
    end
    msg_handler.msg_verbose "#{month_per_month_record_map.size} #{per_month} records created."
    return month_per_month_record_map
  end

  def self.events_by_date( name:, cc_id: nil, data_name: nil, date_range: nil, group_by_day: true )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "name=#{name}",
                                           "cc_id=#{cc_id}",
                                           "data_name=#{data_name}",
                                           "date_range=#{date_range_readable(date_range)}",
                                           "" ] if analytics_helper_debug_verbose

    if date_range.blank? && ::Deepblue::AnalyticsIntegrationService.hit_graph_day_window > 0
      date_range = ::Deepblue::AnalyticsIntegrationService.hit_graph_day_window.days.ago..(Date.today + 1.day)
    end
    rv = if cc_id.present?
           if date_range.blank?
             if group_by_day
               Ahoy::Event.where( name: name, cc_id: cc_id ).group_by_day( :time ).count
             else
               Ahoy::Event.where( name: name, cc_id: cc_id ).count
             end
           else
             sql = Ahoy::Event.where( name: name, cc_id: cc_id, time: date_range ).to_sql
             sql = Ahoy::Event.where( name: name, cc_id: cc_id, time: date_range ).group_by_day( :time ).to_sql if group_by_day
             ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                    ::Deepblue::LoggingHelper.called_from,
                                                    "sql=#{sql}",
                                                    "" ] if analytics_helper_debug_verbose
             if group_by_day       
               Ahoy::Event.where( name: name,
                                  cc_id: cc_id,
                                  time: date_range ).group_by_day( :time ).count
             else
               Ahoy::Event.where( name: name,
                                  cc_id: cc_id,
                                  time: date_range ).count
             end
           end
         elsif date_range.present?
           if group_by_day
             Ahoy::Event.where( name: name, time: date_range ).group_by_day( :time ).count
           else
             Ahoy::Event.where( name: name, time: date_range ).count
           end
         else
           if group_by_day
             Ahoy::Event.where( name: name ).group_by_day( :time ).count
           else
             Ahoy::Event.where( name: name ).count
           end
         end
    rv = { name: data_name, data: rv } if data_name.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "name=#{name}",
                                           "cc_id=#{cc_id}",
                                           "data_name=#{data_name}",
                                           "date_range=#{date_range_readable(date_range)}",
                                           "rv=#{rv}",
                                           "" ] if analytics_helper_debug_verbose
    return rv
  end

  def self.file_set_condensed_events_guard( cc_id:, timestamp: gmtnow, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "cc_id=#{cc_id}",
                             "timestamp=#{timestamp}",
                             "" ] if debug_verbose
    guard = Ahoy::CondensedEvent.find_or_create_by( name: FILE_SET_CONDENSED, cc_id: cc_id )
    guard.date_begin = timestamp
    guard.date_end = timestamp
    guard.save!
  end

  def self.file_set_condensed_events_guard?( cc_id: )
    guard = Ahoy::CondensedEvent.find_by( name: FILE_SET_CONDENSED, cc_id: cc_id )
    guard.present?
  end

  def self.file_set_hits_by_date( controller_class:, cc_id: nil, date_range: nil )
    visits = events_by_date( name: "#{controller_class.name}#show",
                             cc_id: cc_id,
                             data_name: "visits",
                             date_range: date_range )
    downloads = events_by_date( name: DOWNLOAD_EVENT, cc_id: cc_id, data_name: "downloads", date_range: date_range )
    [ visits, downloads ]
  end

  def self.file_set_total_downloads_for_month( id:, date_in_month: )
    date_range = date_range_for_month_of( time: date_in_month )
    records = Ahoy::CondensedEvent.where( name: FILE_SET_DWNLDS_PER_MONTH,
                                          cc_id: id,
                                          date_begin: date_range.first,
                                          date_end: date_range.last )
    return 0 unless records.present?
    r = records.first
    return 0 unless r.condensed_event.present?
    total_downloads = r.condensed_event['total_downloads']
    total_downloads ||= 0
    return total_downloads
  end

  def self.gmtnow
    Time.now.getgm
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

  def self.initialize_condensed_events_progress( msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    works = ::Ahoy::CondensedEvent.where( name: AnalyticsHelper::WORK_CONDENSED ).size
    file_sets = ::Ahoy::CondensedEvent.where( name: AnalyticsHelper::FILE_SET_CONDENSED ).size
    high_traffic_ips = ::Ahoy::CondensedEvent.where( name: AnalyticsHelper::HIGH_TRAFFIC_IP ).size
    total = ::Ahoy::CondensedEvent.all.size
    msg_handler.msg "Works condensed: #{works}; File sets condensed: #{file_sets}; High traffic ips found: #{high_traffic_ips}; Total condensed events: #{total};"
  end

  # This is just needed at the time the stats are setup from rails console
  def self.initialize_condensed_event_downloads( force: DEFAULT_FORCED,
                                                 only_published: DEFAULT_ONLY_PUBLISHED,
                                                 incremental_clean_work_events: DEFAULT_CLEAN_WORK_EVENTS,
                                                 msg_handler: nil )

    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "force=#{force}",
                             "only_published=#{only_published}",
                             "incremental_clean_work_events=#{incremental_clean_work_events}",
                             "skip_admin_events=#{skip_admin_events}",
                             "" ] if debug_verbose
    msg_handler.msg_verbose "force=#{force}"
    msg_handler.msg_verbose "only_published=#{only_published}"
    msg_handler.msg_verbose "incremental_clean_work_events=#{incremental_clean_work_events}"
    msg_handler.msg_verbose "skip_admin_events=#{skip_admin_events}"
    msg_handler.msg_verbose "Started: #{gmtnow}"
    DataSet.all.each do |work|
      initialize_condensed_event_downloads_for_work( work: work,
                                                     force: force,
                                                     only_published: only_published,
                                                     incremental_clean_work_events: incremental_clean_work_events,
                                                     msg_handler: msg_handler )
    end
    msg_handler.msg_verbose "Finished: #{gmtnow}"
    return nil
  end

  def self.initialize_condensed_event_downloads_for_work( work:,
                                                          force: DEFAULT_FORCED,
                                                          only_published: DEFAULT_ONLY_PUBLISHED,
                                                          incremental_clean_work_events: DEFAULT_CLEAN_WORK_EVENTS,
                                                          msg_handler: nil )

    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "work.id=#{work.id}",
                             "force=#{force}",
                             "only_published=#{only_published}",
                             "incremental_clean_work_events=#{incremental_clean_work_events}",
                             "" ] if debug_verbose
    msg_handler.msg_verbose "Initialize work #{work.id} started."
    if only_published && !work.published?
      msg_handler.msg_verbose "Initialize work #{work.id} skipped because not published."
      return
    end
    if work_condensed_events_guard?( cc_id: work.id )
      msg_handler.msg_verbose "Initialize work #{work.id} skipped because of guard."
      return
    end
    drop_condensed_event_downloads_for_work( work: work, msg_handler: msg_handler ) if incremental_clean_work_events
    initialize_condensed_event_downloads_for_work_files( work: work,
                                                         force: force,
                                                         only_published: only_published,
                                                         incremental_clean_work_events: incremental_clean_work_events,
                                                         msg_handler: msg_handler )
    initialize_condensed_event_downloads_for_work_event( work: work,
                                                         download_event: WORK_ZIP_DOWNLOAD_EVENT,
                                                         per_month_event: WORK_ZIP_DWNLDS_PER_MONTH,
                                                         to_date_event: WORK_ZIP_DWNLDS_TO_DATE,
                                                         force: force,
                                                         only_published: only_published,
                                                         incremental_clean_work_events: incremental_clean_work_events,
                                                         msg_handler: msg_handler )
    initialize_condensed_event_downloads_for_work_event( work: work,
                                                         download_event: WORK_GLOBUS_EVENT,
                                                         per_month_event: WORK_GLOBUS_DWNLDS_PER_MONTH,
                                                         to_date_event: WORK_GLOBUS_DWNLDS_TO_DATE,
                                                         force: force,
                                                         only_published: only_published,
                                                         incremental_clean_work_events: incremental_clean_work_events,
                                                         msg_handler: msg_handler )
    msg_handler.msg_verbose "Initialize work #{work.id} finished."
    work_condensed_events_guard( cc_id: work.id )
    return nil
  end

  def self.initialize_condensed_event_downloads_for_work_event( work:,
                                                                download_event:,
                                                                per_month_event:,
                                                                to_date_event:,
                                                                force: DEFAULT_FORCED,
                                                                only_published: DEFAULT_ONLY_PUBLISHED,
                                                                incremental_clean_work_events: DEFAULT_CLEAN_WORK_EVENTS,
                                                                msg_handler: nil )

    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "work.id=#{work.id}",
                             "download_event=#{download_event}",
                             "per_month_event=#{per_month_event}",
                             "to_date_event=#{to_date_event}",
                             "force=#{force}",
                             "only_published=#{only_published}",
                             "incremental_clean_work_events=#{incremental_clean_work_events}",
                             "" ] if debug_verbose
    if only_published && !work.published?
      # msg_handler.msg_verbose "Skipping unpublished work: #{work.id}"
      return
    end

    drop_condensed_events_by_id( cc_id: work.id, event: per_month_event, msg_handler: msg_handler )
    drop_condensed_events_by_id( cc_id: work.id, event: to_date_event, msg_handler: msg_handler )
    month_per_month_record_map = event_records_for( event: download_event,
                                                    cc_id: work.id,
                                                    date_range: date_range_all,
                                                    per_month: per_month_event,
                                                    msg_handler: msg_handler )
    month_per_month_record_map.each_pair do |_date_begin,record|
      skip_predicate = ->(record, msg_handler) { download_event_skip_non_file?( record, msg_handler ) }
      ip_event_count_map = initialize_visit_event_map( event: download_event,
                                                       cc_id: work.id,
                                                       month: date_range_from( record ),
                                                       skip_predicate: skip_predicate,
                                                       msg_handler: msg_handler )
      store_condensed_event_total_downloads( record: record,
                                             ip_event_count_map: ip_event_count_map,
                                             msg_handler: msg_handler )

    end
    store_sum_of_monthly_total_downloads( per_month_event: per_month_event,
                                          to_date_event: to_date_event,
                                          cc_id: work.id,
                                          force: true,
                                          msg_handler: msg_handler )
    delete_condensed_events_total_downloads_zero( name: per_month_event, cc_id: work.id, msg_handler: msg_handler )
    delete_condensed_events_total_downloads_zero( name: to_date_event, cc_id: work.id, msg_handler: msg_handler )
  end

  def self.initialize_condensed_event_downloads_for_work_files( work:,
                                                                force: DEFAULT_FORCED,
                                                                only_published: DEFAULT_ONLY_PUBLISHED,
                                                                incremental_clean_work_events: DEFAULT_CLEAN_WORK_EVENTS,
                                                                msg_handler: nil )

    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "work.id=#{work.id}",
                             "force=#{force}",
                             "only_published=#{only_published}",
                             "incremental_clean_work_events=#{incremental_clean_work_events}",
                             "" ] if debug_verbose

    work.file_set_ids.each do |fid|
      if file_set_condensed_events_guard?( cc_id: fid )
        msg_handler.msg_verbose "Initialize file set #{fid} skipped because of guard."
        next
      end
      # clean out any existing file set download condensed events
      drop_condensed_events_by_id( cc_id: fid, event: FILE_SET_DWNLDS_PER_MONTH, msg_handler: msg_handler )
      drop_condensed_events_by_id( cc_id: fid, event: FILE_SET_DWNLDS_TO_DATE, msg_handler: msg_handler )
      month_per_month_record_map = event_records_for( event: DOWNLOAD_EVENT,
                                                      cc_id: fid,
                                                      date_range: date_range_all,
                                                      per_month: FILE_SET_DWNLDS_PER_MONTH,
                                                      msg_handler: msg_handler )
      month_per_month_record_map.each_pair do |_date_begin,record|
        skip_predicate = ->(record, msg_handler) { download_event_skip_file?( record, msg_handler: msg_handler ) }
        month = date_range_from( record )
        ip_event_count_map = initialize_visit_event_map( event: DOWNLOAD_EVENT,
                                                         cc_id: fid,
                                                         month: month,
                                                         skip_predicate: skip_predicate,
                                                         msg_handler: msg_handler )
        store_condensed_event_total_downloads( record: record,
                                               ip_event_count_map: ip_event_count_map,
                                               msg_handler: msg_handler )
        merge_work_file_total_downloads( work_id: work.id,
                                         fid: fid,
                                         condensed_event: record.condensed_event,
                                         month: month,
                                         msg_handler: msg_handler )
      end
      store_sum_of_monthly_total_downloads( per_month_event: FILE_SET_DWNLDS_PER_MONTH,
                                            to_date_event: FILE_SET_DWNLDS_TO_DATE,
                                            cc_id: fid,
                                            force: true,
                                            msg_handler: msg_handler )
      delete_condensed_events_total_downloads_zero( name: FILE_SET_DWNLDS_PER_MONTH, cc_id: fid, msg_handler: msg_handler )
      delete_condensed_events_total_downloads_zero( name: FILE_SET_DWNLDS_TO_DATE, cc_id: fid, msg_handler: msg_handler )
      file_set_condensed_events_guard( cc_id: fid )
    end
    store_sum_of_monthly_total_downloads( per_month_event: WORK_FILE_DWNLDS_PER_MONTH,
                                          to_date_event: WORK_FILE_DWNLDS_TO_DATE,
                                          cc_id: work.id,
                                          force: true,
                                          msg_handler: msg_handler )
    delete_condensed_events_total_downloads_zero( name: WORK_FILE_DWNLDS_PER_MONTH, cc_id: work.id, msg_handler: msg_handler )
    delete_condensed_events_total_downloads_zero( name: WORK_FILE_DWNLDS_TO_DATE, cc_id: work.id, msg_handler: msg_handler )
  end

  def self.initialize_rather_than_update_work?( work:, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    return false if Ahoy::CondensedEvent.where( name: WORK_CONDENSED, cc_id: work.id ).count > 0
    return true
  end

  # for a given cc_id and event over a month, collect the events from Ahoy
  # then for each
  # skip if thumbnail download (i.e. the skip predicate is true)
  # get the event ip
  # skip if ip is blank
  # then, based on ip, count
  # if count is high enough (100 hits), turn into a high traffic ip
  # return the ip -> count map
  def self.initialize_visit_event_map( event:,
                                       cc_id:,
                                       month:,
                                       skip_predicate: ->(record,msg_handler) { false },
                                       visit_id_to_ip_map: nil,
                                       ip_event_count_map: nil,
                                       msg_handler: nil )

    verbose = false
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "event=#{event}",
                             "cc_id=#{cc_id}",
                             "month=#{date_range_readable month}",
                             "visit_id_to_ip_map&.size=#{session_id_to_ip_map&.size}",
                             "" ] if debug_verbose
    msg_handler.msg_verbose {"initialize_visit_map(event:#{event}, cc_id: #{cc_id}, month: #{date_range_readable month})"} if verbose
    visit_id_to_ip_map ||= {}
    ip_event_count_map ||= {}
    records = Ahoy::Event.where( name: event, cc_id: cc_id, time: month )
    msg_handler.msg_verbose {"#{records.size} records found."}  if verbose
    records.each do |record|
      if skip_predicate.call(record, msg_handler)
        # msg_handler.msg_verbose "Skip event #{record.inspect}" if verbose
        next
      end
      msg_handler.msg_verbose {"Event map record=#{records.inspect}"} if verbose
      visit_id = record.visit_id
      ip = visit_id_to_ip_map[visit_id]
      msg_handler.msg_verbose {"visit_id_to_ip_map[#{visit_id}]=#{ip}"} if verbose
      if ip.nil?
        visit = Ahoy::Visit.where( id: visit_id )
        next if visit.nil?
        ip = visit.first.ip
        next if ip.blank?
        msg_handler.msg_verbose {"Map #{visit_id} to #{ip}"} if verbose
        visit_id_to_ip_map[visit_id] = ip
        if Ahoy::CondensedEvent.where( name: HIGH_TRAFFIC_IP, cc_id: ip ).present?
          ip_event_count_map[ip] = HIGH_TRAFFIC
        else
          ip_event_count_map[ip] = 0
        end
      end
      event_count = ip_event_count_map[ip]
      msg_handler.msg_verbose {"ip_event_count_map[#{ip}]=#{event_count == HIGH_TRAFFIC ? 'HIGH_TRAFFIC' : event_count.to_s}"} if verbose
      next if HIGH_TRAFFIC == event_count
      msg_handler.msg_verbose "counting the event" if verbose
      event_count += 1
      if event_count <= max_visits_per_month_filter
        ip_event_count_map[ip] = event_count
      else
        msg_handler.msg_verbose {"Creating HIGH_TRAFFIC_IP for ip=#{ip}"} if verbose
        ip_event_count_map[ip] = HIGH_TRAFFIC
        Ahoy::CondensedEvent.new( name: HIGH_TRAFFIC_IP, cc_id: ip ).save!
      end
    end
    return ip_event_count_map
  end

  def self.merge_work_file_total_downloads( work_id:,
                                            fid:,
                                            condensed_event:,
                                            month:,
                                            msg_handler: nil )

    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    per_month_record = Ahoy::CondensedEvent.find_or_create_by( name: WORK_FILE_DWNLDS_PER_MONTH,
                                                               cc_id: work_id,
                                                               date_begin: month.first,
                                                               date_end: month.last )
    file_total_downloads = condensed_event['total_downloads']
    work_condensed_event = per_month_record.condensed_event
    if 0 == file_total_downloads && work_condensed_event.nil?
      work_condensed_event = total_downloads( 0 )
      per_month_record.condensed_event = work_condensed_event
      per_month_record.save!
    elsif 0 < file_total_downloads
      work_condensed_event ||= total_downloads( 0 )
      total_downloads = work_condensed_event['total_downloads']
      total_downloads += file_total_downloads
      work_condensed_event['total_downloads'] = total_downloads
      work_condensed_event[fid] = file_total_downloads
      per_month_record.condensed_event = work_condensed_event
      per_month_record.save!
    else
      # no update necessary
    end
  end


  def self.monthly_analytics_report( date_range: nil, debug_verbose: analytics_helper_debug_verbose )
    debug_verbose = debug_verbose || analytics_helper_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "date_range=#{date_range_readable date_range}",
                                           "" ] if debug_verbose
    subscribers = monthly_analytics_report_subscribers( debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "subscribers=#{subscribers}",
                                           "" ] if debug_verbose
    return if subscribers.blank?
    date_range = date_range_for_month_of( time: gmtnow.beginning_of_month - 1.day ) if date_range.blank?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "date_range=#{date_range_readable(date_range)}",
                                           "" ] if debug_verbose
    subscribers.each do |email|
      monthly_analytics_report_for( email: email, date_range: date_range, debug_verbose: debug_verbose )
    end
  end

  def self.monthly_analytics_report_for( email:, date_range:, debug_verbose: analytics_helper_debug_verbose )
    debug_verbose = debug_verbose || analytics_helper_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "email=#{email}",
                                           "date_range=#{date_range_readable(date_range)}",
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
    debug_verbose = debug_verbose || analytics_helper_debug_verbose
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

    debug_verbose = debug_verbose || analytics_helper_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "date_range=#{date_range_readable(date_range)}",
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
                                 event_note: "Month: #{month}",
                                 id: "N/A",
                                 to: email,
                                 subject: subject,
                                 body: body,
                                 content_type: content_type,
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
    record.save!
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
    record = EmailSubscription.find_by( subscription_name: monthly_analytics_report_subscription_id, user_id: user.id )
    return unless record.present?
    record.delete
  end

  def self.monthly_events_report( date_range: nil, debug_verbose: analytics_helper_debug_verbose )
    debug_verbose = debug_verbose || analytics_helper_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "date_range=#{date_range_readable(date_range)}",
                                           "" ] if debug_verbose
    subscribers = monthly_events_report_subscribers
    return if subscribers.blank?
    date_range = date_range_for_month_of( time: gmtnow.beginning_of_month - 1.day ) if date_range.blank?
    subscribers.each do |email_params_pair|
      email = email_params_pair[0]
      params = email_params_pair[1]
      next if params.blank?
      monthly_events_report_for( email: email, params: params, date_range: date_range, debug_verbose: debug_verbose )
    end
  end

  def self.monthly_events_report_for( email:, params:, date_range:, debug_verbose: analytics_helper_debug_verbose )
    debug_verbose = debug_verbose || analytics_helper_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "email=#{email}",
                                           "params=#{params}",
                                           "date_range=#{date_range_readable(date_range)}",
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

    debug_verbose = debug_verbose || analytics_helper_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "date_range=#{date_range_readable(date_range)}",
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
                                 event_note: "Month: #{month}",
                                 id: "N/A",
                                 to: email,
                                 subject: subject,
                                 body: body,
                                 content_type: content_type,
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
    record.save!
  end

  # convenience method, TODO: move to DataSetsController
  def self.monthly_events_report_subscribe_data_set( user:, cc_id: )
    monthly_events_report_subscribe( user: user,
                                     cc_id: cc_id,
                                     event_names: [ WORK_SHOW_EVENT,
                                                    WORK_ZIP_DOWNLOAD_EVENT,
                                                    WORK_GLOBUS_EVENT ] )
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
    record.save!
  end

  def self.monthly_hits_by_date_and_name( id:, name:, date_range: )
    return 0 if id.blank?
    return 0 if date_range.blank?
    r = Ahoy::CondensedEvent.find_by( name: name, cc_id: id, date_begin: date_range.first, date_end: date_range.last )
    return 0 if r.blank?
    return r.condensed_event['total_downloads']
  end

  def self.normalize_begin_end_dates( msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    ::Ahoy::CondensedEvent.all.each do |condensed_event|
      normalize_begin_end_dates_for( condensed_event: condensed_event, msg_handler: msg_handler )
    end
    return nil
  end

  def self.normalize_begin_end_dates_for( condensed_event:, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    # TODO: skip save if date_range already normalized
    per_month = ->(ce) { dr = date_range_for_month_of(time: ce.date_begin); ce.date_begin = dr.first; ce.date_end = dr.last }
    simple = ->(ce) { ce.date_begin = ce.date_begin.getgm; ce.date_end = ce.date_end.getgm; }
    to_date = ->(ce) { ce.date_begin = BEGINNING_OF_TIME; ce.date_end = END_OF_TIME }
    case condensed_event.name
    when FILE_SET_CONDENSED
      simple.call(condensed_event)
    when WORK_CONDENSED
      simple.call(condensed_event)
    when FILE_SET_DWNLDS_TO_DATE
      to_date.call(condensed_event)
    when WORK_FILE_DWNLDS_TO_DATE
      to_date.call(condensed_event)
    when WORK_GLOBUS_DWNLDS_TO_DATE
      to_date.call(condensed_event)
    when WORK_ZIP_DWNLDS_TO_DATE
      to_date.call(condensed_event)
    else
      per_month.call(condensed_event)
    end
    condensed_event.save!
  end

  def self.open_analytics_report_subscriptions?
    Flipflop.open_analytics_report_subscriptions?
  end

  def self.page_hits_by_date( controller_class:, cc_id: nil, date_range: nil )
    events_by_date( name: "#{controller_class.name}#show", cc_id: cc_id, date_range: date_range )
  end

  def self.show_hit_graph?( current_ability, presenter: nil )
    return false unless enable_local_analytics_ui?
    # 0 = none, 1 = admin, 2 = editor, 3 = everyone
    return false if presenter && presenter.respond_to?( :anonymous_show? ) && presenter.anonymous_show?
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

  # sum the counts, ignoring if high traffic
  def self.store_condensed_event_total_downloads( record:, ip_event_count_map:, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    total_downloads = 0
    ip_event_count_map.each_pair do |_ip,count|
      next if HIGH_TRAFFIC == count
      total_downloads += count
    end
    record.condensed_event = total_downloads( total_downloads )
    msg_handler.msg_verbose {"Store #{record.name} #{record.cc_id} #{date_range_readable record.date_begin..record.date_end} #{record.condensed_event}"}
    record.save!
  end

  def self.store_sum_of_monthly_total_downloads( per_month_event:, to_date_event:, cc_id:, force:, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    condensed_event = sum_total_downloads( event: per_month_event, cc_id: cc_id, msg_handler: msg_handler )
    msg_handler.msg_verbose "Sum for #{per_month_event} to #{to_date_event} #{cc_id} is #{condensed_event}."
    store_total_downloads( event: to_date_event,
                           id: cc_id,
                           condensed_event: condensed_event,
                           date_range: date_range_all,
                           force: true,
                           msg_handler: msg_handler )
  end

  # store total downloads and return the condensed event hash
  def self.store_total_downloads( event:,
                                  id:,
                                  condensed_event:,
                                  date_range:,
                                  force: DEFAULT_FORCED,
                                  record: nil,
                                  msg_handler: nil )

    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "event=#{event}",
                             "id=#{id}",
                             "condensed_event=#{condensed_event}",
                             "condensed_event['total_downloads']=#{condensed_event['total_downloads']}",
                             "store_zero_total_downloads=#{store_zero_total_downloads}",
                             "date_range=#{date_range_readable(date_range)}",
                             "record=#{record&.inspect}",
                             "" ] if debug_verbose
    if !store_zero_total_downloads && condensed_event.present? && condensed_event['total_downloads'] == 0
      msg_handler.msg_verbose "Skipping save because total downloads is zero." if debug_verbose
      return condensed_event
    end
    if record.nil?
      msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                               ::Deepblue::LoggingHelper.called_from,
                               "find record",
                               "Ahoy::CondensedEvent.find_by( name: #{event}, cc_id: #{id}, date_begin: #{date_range.first}, date_end: #{date_range.last} )",
                               "" ] if debug_verbose
      record = Ahoy::CondensedEvent.find_by( name: event,
                                             cc_id: id,
                                             date_begin: date_range.first,
                                             date_end: date_range.last )
      msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                               ::Deepblue::LoggingHelper.called_from,
                               "record found=#{record&.inspect}",
                               "" ] if debug_verbose
    end
    if record.present? && !force
      msg_handler.msg_verbose "Skipping save because record present and not force update." if debug_verbose
      return record.condensed_event
    end
    if record.nil?
      msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                               ::Deepblue::LoggingHelper.called_from,
                               "create record",
                               "" ] if debug_verbose
      record = Ahoy::CondensedEvent.new( name: event,
                                         cc_id: id,
                                         date_begin: date_range.first,
                                         date_end: date_range.last )
    end
    record.condensed_event = condensed_event
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "save record=#{record.inspect}",
                             "" ] if debug_verbose
    record.save!
    msg_handler.msg_verbose {"Store #{record.name} #{record.cc_id} #{date_range_readable record.date_begin..record.date_end} #{record.condensed_event}"}
    # msg_handler.msg_verbose "save record=#{record.inspect}"
    return condensed_event
  end

  def self.sum_total_downloads( event:, cc_id:, date_filter: nil, condensed_event: nil, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    verbose = false
    condensed_event = total_downloads( 0 ) unless condensed_event
    records = ::Ahoy::CondensedEvent.where( name: event, cc_id: cc_id )
    msg_handler.msg_verbose {"#{records.size} found for event #{event} and cc_id #{cc_id}"} if verbose
    return condensed_event unless records.present?
    records.each do |record|
      if date_filter.present?
        date = record.date_begin
        unless date >= date_filter.first && date <= date_filter.last
          msg_handler.msg_verbose {"Filter out #{record.inspect}"} if verbose
          next
        end
      end
      msg_handler.msg_verbose {"Adding #{record.condensed_event}"} if verbose
      msg_handler.msg_verbose {"keys #{record.condensed_event.keys}"} if verbose
      record.condensed_event.keys.each do |key|
        msg_handler.msg_verbose {"Processing record key #{key} value #{record.condensed_event[key]}"} if verbose
        if condensed_event.has_key? key
          condensed_event[key] = condensed_event[key] + record.condensed_event[key]
        else
          condensed_event[key] = record.condensed_event[key]
        end
        msg_handler.msg_verbose {"Processing condensed_event key #{key} value #{condensed_event[key]}"} if verbose
      end
    end
    msg_handler.msg_verbose {"returning condensed_event=#{condensed_event}"} if verbose
    return condensed_event
  end

  def self.total_downloads_from( condensed_event: )
    return 0 if condensed_event.nil?
    total_downloads = condensed_event['total_downloads']
    return 0 if total_downloads.blank?
    return total_downloads
  end

  def self.total_downloads( total_downloads )
    { 'total_downloads' => total_downloads }
  end

  def self.total_downloads_zero?( record )
    return false if record.blank?
    return false if record.condensed_event.blank?
    total_downloads = record.condensed_event['total_downloads']
    return false if total_downloads.blank?
    return 0 == total_downloads
  end

  def self.truncate_date( time )
    time.getutc + time.gmt_offset.seconds
  end

  def self.update_condensed_event_downloads( force: DEFAULT_FORCED,
                                             only_published: DEFAULT_ONLY_PUBLISHED,
                                             msg_handler: nil )


    # TODO: this should be able to be run as many times as needed during a month

    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "force=#{force}",
                             "only_published=#{only_published}",
                             "skip_admin_events=#{skip_admin_events}",
                             "" ] if debug_verbose
    msg_handler.msg_verbose "force=#{force}"
    msg_handler.msg_verbose "only_published=#{only_published}"
    msg_handler.msg_verbose "skip_admin_events=#{skip_admin_events}"
    msg_handler.msg_verbose "Started: #{gmtnow}"

    date_range_month_previous = date_range_for_month_previous
    date_range_month_current = date_range_for_month_of( time: gmtnow )
    msg_handler.msg_verbose "date_range_month_previous=#{date_range_readable date_range_month_previous}"
    msg_handler.msg_verbose "date_range_month_current=#{date_range_readable date_range_month_current}"

    DataSet.all.each do |work|
      update_condensed_event_downloads_for_work( work: work,
                                                 force: force,
                                                 only_published: only_published,
                                                 date_range_month_previous: date_range_month_previous,
                                                 date_range_month_current: date_range_month_current,
                                                 msg_handler: msg_handler )
    end
    msg_handler.msg_verbose "Finished: #{gmtnow}"
    return nil
  end

  def self.update_condensed_event_downloads_for_work( work:,
                                                      force: DEFAULT_FORCED,
                                                      only_published: DEFAULT_ONLY_PUBLISHED,
                                                      date_range_month_previous:,
                                                      date_range_month_current:,
                                                      msg_handler: nil )

    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "work.id=#{work.id}",
                             "force=#{force}",
                             "only_published=#{only_published}",
                             "date_range_month_previous=#{date_range_readable date_range_month_previous}",
                             "date_range_month_current=#{date_range_readable date_range_month_current}",
                             "" ] if debug_verbose
    msg_handler.msg_verbose "Update work #{work.id} started."
    if only_published && !work.published?
      msg_handler.msg_verbose "Update work #{work.id} skipped because not published."
      return
    end
    if initialize_rather_than_update_work?( work: work, msg_handler: msg_handler )
      initialize_condensed_event_downloads_for_work( work: work, force: force,
                                                     only_published: only_published,
                                                     msg_handler: msg_handler )
      return
    end
    update_condensed_event_downloads_for_work_files( work: work,
                                                     force: force,
                                                     only_published: only_published,
                                                     date_range_month_previous: date_range_month_previous,
                                                     date_range_month_current: date_range_month_current,
                                                     msg_handler: msg_handler )
    update_condensed_event_downloads_for_work_event( work: work,
                                                     download_event: WORK_ZIP_DOWNLOAD_EVENT,
                                                     per_month_event: WORK_ZIP_DWNLDS_PER_MONTH,
                                                     to_date_event: WORK_ZIP_DWNLDS_TO_DATE,
                                                     force: force,
                                                     only_published: only_published,
                                                     date_range_month_previous: date_range_month_previous,
                                                     date_range_month_current: date_range_month_current,
                                                     msg_handler: msg_handler )
    update_condensed_event_downloads_for_work_event( work: work,
                                                     download_event: WORK_GLOBUS_EVENT,
                                                     per_month_event: WORK_GLOBUS_DWNLDS_PER_MONTH,
                                                     to_date_event: WORK_GLOBUS_DWNLDS_TO_DATE,
                                                     force: force,
                                                     only_published: only_published,
                                                     date_range_month_previous: date_range_month_previous,
                                                     date_range_month_current: date_range_month_current,
                                                     msg_handler: msg_handler )
    msg_handler.msg_verbose "Update work #{work.id} finished."
    return nil
  end

  def self.update_condensed_event_downloads_for_work_event( work:,
                                                            download_event:,
                                                            per_month_event:,
                                                            to_date_event:,
                                                            force: DEFAULT_FORCED,
                                                            only_published: DEFAULT_ONLY_PUBLISHED,
                                                            date_range_month_previous:,
                                                            date_range_month_current:,
                                                            msg_handler: nil )

    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "work.id=#{work.id}",
                             "download_event=#{download_event}",
                             "per_month_event=#{per_month_event}",
                             "to_date_event=#{to_date_event}",
                             "force=#{force}",
                             "only_published=#{only_published}",
                             "date_range_month_previous=#{date_range_readable date_range_month_previous}",
                             "date_range_month_current=#{date_range_readable date_range_month_current}",
                             "" ] if debug_verbose
    if only_published && !work.published?
      # msg_handler.msg_verbose "Skipping unpublished work: #{work.id}"
      return
    end
    date_range_two_months = date_range_expand( date_range_month_previous, date_range_month_current )
    month_per_month_record_map = event_records_for( event: download_event,
                                                    cc_id: work.id,
                                                    date_range: date_range_two_months,
                                                    per_month: per_month_event,
                                                    msg_handler: msg_handler )
    month_per_month_record_map.each_pair do |_date_begin,record|
      skip_predicate = ->(record, msg_handler) { download_event_skip_non_file?( record, msg_handler ) }
      ip_event_count_map = initialize_visit_event_map( event: download_event,
                                                       cc_id: work.id,
                                                       month: date_range_from( record ),
                                                       skip_predicate: skip_predicate,
                                                       msg_handler: msg_handler )
      store_condensed_event_total_downloads( record: record,
                                             ip_event_count_map: ip_event_count_map,
                                             msg_handler: msg_handler )
    end
    store_sum_of_monthly_total_downloads( per_month_event: per_month_event,
                                          to_date_event: to_date_event,
                                          cc_id: work.id,
                                          force: true,
                                          msg_handler: msg_handler )
    delete_condensed_events_total_downloads_zero( name: per_month_event, cc_id: work.id, msg_handler: msg_handler )
    delete_condensed_events_total_downloads_zero( name: to_date_event, cc_id: work.id, msg_handler: msg_handler )
  end

  def self.update_condensed_event_downloads_for_work_files( work:,
                                                            force: DEFAULT_FORCED,
                                                            only_published: DEFAULT_ONLY_PUBLISHED,
                                                            date_range_month_previous:,
                                                            date_range_month_current:,
                                                            msg_handler: nil )

    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "work.id=#{work.id}",
                             "force=#{force}",
                             "only_published=#{only_published}",
                             "date_range_month_previous=#{date_range_readable date_range_month_previous}",
                             "date_range_month_current=#{date_range_readable date_range_month_current}",
                             "" ] if debug_verbose
    if only_published && !work.published?
      # msg_handler.msg_verbose "Skipping unpublished work: #{work.id}"
      return
    end
    delete_condensed_event_monthly( name: WORK_GLOBUS_DWNLDS_PER_MONTH, cc_id: work.id, month: date_range_month_previous )
    delete_condensed_event_monthly( name: WORK_GLOBUS_DWNLDS_PER_MONTH, cc_id: work.id, month: date_range_month_current )
    work.file_set_ids.each do |fid|
      date_range_two_months = date_range_expand( date_range_month_previous, date_range_month_current )
      month_per_month_record_map = event_records_for( event: DOWNLOAD_EVENT,
                                                      cc_id: fid,
                                                      date_range: date_range_two_months,
                                                      per_month: FILE_SET_DWNLDS_PER_MONTH,
                                                      msg_handler: msg_handler )
      month_per_month_record_map.each_pair do |_date_begin,record|
        skip_predicate = ->(record, msg_handler) { download_event_skip_file?( record, msg_handler: msg_handler ) }
        month = date_range_from( record )
        ip_event_count_map = initialize_visit_event_map( event: DOWNLOAD_EVENT,
                                                         cc_id: fid,
                                                         month: month,
                                                         skip_predicate: skip_predicate,
                                                         msg_handler: msg_handler )
        store_condensed_event_total_downloads( record: record,
                                               ip_event_count_map: ip_event_count_map,
                                               msg_handler: msg_handler )
        merge_work_file_total_downloads( work_id: work.id,
                                         fid: fid,
                                         condensed_event: record.condensed_event,
                                         month: month,
                                         msg_handler: msg_handler )
      end
      store_sum_of_monthly_total_downloads( per_month_event: FILE_SET_DWNLDS_PER_MONTH,
                                            to_date_event: FILE_SET_DWNLDS_TO_DATE,
                                            cc_id: fid,
                                            force: true,
                                            msg_handler: msg_handler )
      delete_condensed_events_total_downloads_zero( name: FILE_SET_DWNLDS_PER_MONTH, cc_id: fid, msg_handler: msg_handler )
      delete_condensed_events_total_downloads_zero( name: FILE_SET_DWNLDS_TO_DATE, cc_id: fid, msg_handler: msg_handler )
    end
    store_sum_of_monthly_total_downloads( per_month_event: WORK_FILE_DWNLDS_PER_MONTH,
                                          to_date_event: WORK_FILE_DWNLDS_TO_DATE,
                                          cc_id: work.id,
                                          force: true,
                                          msg_handler: msg_handler )
    delete_condensed_events_total_downloads_zero( name: WORK_FILE_DWNLDS_PER_MONTH, cc_id: work.id, msg_handler: msg_handler )
    delete_condensed_events_total_downloads_zero( name: WORK_FILE_DWNLDS_TO_DATE, cc_id: work.id, msg_handler: msg_handler )
  end

  def self.update_condensed_events_for( date_range:, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    name_cc_ids = Ahoy::Event.select( :name, :cc_id ).where( time: date_range ).distinct.pluck( :name,
                                                                                                :cc_id )
    msg_handler.msg_verbose {"#{name_cc_ids.size} name and cc_ids found."}
    name_cc_ids.each do |name_cc_id|
      name = name_cc_id[0]
      cc_id = name_cc_id[1]
      msg_handler.msg_verbose {"Process event #{name}, #{cc_id}"}
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

  # TODO: review the use of this method and what it does
  def self.update_current_month_condensed_events( date_range: nil, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    if date_range.blank?
      # will there be an issue with daily savings time?
      beginning_of_month = gmtnow.beginning_of_month.beginning_of_day
      end_of_month = beginning_of_month.end_of_month.end_of_day
      date_range = beginning_of_month..end_of_month
    end
    update_condensed_events_for( date_range: date_range, msg_handler: msg_handler )
  end

  #
  # TODO: remove this method and replace with update_condensed_event_downloads
  # this is called by the cronjob in UpdateCondensedEventsJob
  def self.updated_condensed_event_work_downloads( force: DEFAULT_FORCED,
                                                   only_published: DEFAULT_ONLY_PUBLISHED,
                                                   msg_handler: nil )

    # for now, just call the new version
    update_condensed_event_downloads( force: force, only_published: only_published, msg_handler: msg_handler )

  end

  def self.user_is_admin( user_id: )
    email = User.where( id: user_id )&.first&.email
    admin_users = RoleMapper.map["admin"]

    admin_users.include? email
  end

  def self.work_condensed_events_guard( cc_id:, timestamp: gmtnow, msg_handler: nil )
    msg_handler = MSG_HANDLER_DEBUG_ONLY if msg_handler.nil?
    debug_verbose = analytics_helper_debug_verbose
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                             ::Deepblue::LoggingHelper.called_from,
                             "cc_id=#{cc_id}",
                             "timestamp=#{timestamp}",
                             "" ] if debug_verbose
    guard = Ahoy::CondensedEvent.find_or_create_by( name: WORK_CONDENSED, cc_id: cc_id )
    guard.date_begin = timestamp
    guard.date_end = timestamp
    guard.save
  end

  def self.work_condensed_events_guard?( cc_id: )
    guard = Ahoy::CondensedEvent.find_by( name: WORK_CONDENSED, cc_id: cc_id )
    guard.present?
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

  def self.work_file_total_downloads_for_month( id:, date_in_month: )
    date_range = date_range_for_month_of( time: date_in_month )
    records = Ahoy::CondensedEvent.where( name: WORK_FILE_DWNLDS_PER_MONTH,
                                          cc_id: id,
                                          date_begin: date_range.first,
                                          date_end: date_range.last )
    return 0 unless records.present?
    r = records.first
    return 0 unless r.condensed_event.present?
    total_downloads = r.condensed_event['total_downloads']
    total_downloads ||= 0
    return total_downloads
  end

end
