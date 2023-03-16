# frozen_string_literal: true

class EmailDashboardController < ApplicationController

  mattr_accessor :email_dashboard_controller_debug_verbose, default: false

  include ActiveSupport::Concern
  include Blacklight::Base
  include Blacklight::AccessControls::Catalog
  include Hyrax::Breadcrumbs
  include AdminOnlyControllerBehavior
  include ActionView::Helpers::UrlHelper # For link_to

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :build_breadcrumbs, only: [:show]

  class_attribute :presenter_class
  self.presenter_class = EmailDashboardPresenter

  attr_accessor :begin_date, :end_date, :log_entries

  attr_reader :action_error

  def add_get_parm( hash:, key:, parms: )
    value = hash[key]
    return if value.blank?
    parms << "#{key}=#{ERB::Util.html_escape value}"
  end

  def add_remail_button?( hash:, row_index: )
    return row_index > 2 && row_index + 1 == hash.size
  end

  def action
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           ">>> action <<<",
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if email_dashboard_controller_debug_verbose
    action = params[:commit]
    @action_error = false
    msg = case action
          when t( 'simple_form.actions.email_management.reload_email_templates' )
            action_reload_email_templates
          else
            @action_error = true
            "Unkown action #{action}"
          end
    if action_error
      redirect_to email_dashboard_path, alert: msg
    else
      redirect_to email_dashboard_path, notice: msg
    end
  end

  def action_reload_email_templates
    ::Deepblue::WorkViewContentService.load_email_templates
    "Reloaded email templates."
  end

  def begin_date_parm
    begin_date.strftime("%Y-%m-%d")
  end

  def end_date_parm
    end_date.strftime("%Y-%m-%d")
  end

  def find_resend_log_entry( debug_verbose: email_dashboard_controller_debug_verbose )
    debug_verbose = debug_verbose || email_dashboard_controller_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params[:event]=#{params[:event]}",
                                           "params[:id]=#{params[:id]}",
                                           "params[:timestamp]=#{params[:timestamp]}",
                                           "" ] if debug_verbose
    rv = JsonHelper.find_in( log_entries,
                             predicate: ->(log_entry) { log_entry_wanted?(log_entry) },
                             debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "rv=#{rv}",
                                           "" ] if debug_verbose
    return rv
  end

  def log_entries
    @log_entries ||= ::Deepblue::LogFileHelper.log_entries( log_file_path: ::EmailLogger.log_file,
                                                            begin_date: begin_date,
                                                            end_date: end_date,
                                                            raw_key_values: true ).reverse!
  end

  def log_entry_wanted?( log_entry )
    return false unless log_entry.is_a? Hash
    debug_verbose = email_dashboard_controller_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params[:event]=#{params[:event]}",
                                           "params[:id]=#{params[:id]}",
                                           "params[:timestamp]=#{params[:timestamp]}",
                                           "log_entry[:event]=#{log_entry[:event]}",
                                           "log_entry[:id]=#{log_entry[:id]}",
                                           "log_entry[:timestamp]=#{log_entry[:timestamp]}",
                                           "" ] if debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "event: return false unless #{log_entry[:event]} == #{params[:event]}",
                                           "" ] if debug_verbose
    return false unless log_entry[:event] == params[:event]
    if params[:id].present?
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "id: return false unless #{log_entry[:id]} == #{params[:id]}",
                                             "" ] if debug_verbose
      return false unless log_entry[:id] == params[:id]
    else
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "return false if #{log_entry[:id]}",
                                             "" ] if debug_verbose
      return false if log_entry[:id].present?
    end
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "timestamp: return false unless #{log_entry[:timestamp]} == #{params[:timestamp]}",
                                           "" ] if debug_verbose
    return false unless log_entry[:timestamp] == params[:timestamp]
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "log_entry=#{log_entry}",
                                           "return true",
                                           "" ] if debug_verbose
    return true
  end

  def log_parse_entry( entry )
    ::Deepblue::LogFileHelper.log_parse_entry entry
  end

  def log_key_values_to_table( key_values,
                               on_key_values_to_table_body_callback: nil,
                               parse: false,
                               row_key_value_callback: nil,
                               add_css: true,
                               debug_verbose: email_dashboard_controller_debug_verbose )

    debug_verbose ||= email_dashboard_controller_debug_verbose
    row_key_value_callback ||= ->( depth, key, hash, row_index ) do
      return nil unless add_remail_button?( hash: hash, row_index: row_index )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "depth=#{depth}",
                                             "key=#{key}",
                                             "value=#{hash[key]}",
                                             "hash=#{hash}",
                                             "row_index=#{row_index}",
                                             "" ] if debug_verbose || email_dashboard_controller_debug_verbose
      table = JsonHelper.key_values_to_table( hash[key], depth: depth + 1, parse: false, debug_verbose: debug_verbose )
      begin
        parms = []
        parms << "begin_date=#{begin_date_parm}"
        parms << "end_date=#{end_date_parm}"
        add_get_parm( hash: hash, key: 'event', parms: parms )
        add_get_parm( hash: hash, key: 'id', parms: parms )
        add_get_parm( hash: hash, key: 'timestamp', parms: parms )
        link = link_to( "Resend this email.",
                        "/data/email_dashboard_resend?#{parms.join('&')}",
                        class: 'btn btn-default',
                        data: {confirm: t('Confirm resend email?')} )
      rescue => e
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "e=#{e}",
                                               "" ] + e.backtrace[0..20]
        link = "Resend this email."
      end
      css_tr = JsonHelper.css_tr( add: add_css, depth: depth )
      css_td = JsonHelper.css_td_key( add: add_css, depth: depth )
      css_td2 = JsonHelper.css_td( add: add_css, depth: depth )
      row = <<-end_of_row
<tr#{css_tr}>
  <td#{css_td}>#{ERB::Util.html_escape( key )}</td>
  <td#{css_td2}>#{table}</td>
</tr>
<tr#{css_tr}>
  <td#{css_td}>&nbsp;</td>
  <td#{css_td2}>#{link}</td>
</tr>
end_of_row
      return row
    end
    ::Deepblue::LogFileHelper.log_key_values_to_table( key_values,
                                             on_key_values_to_table_body_callback: on_key_values_to_table_body_callback,
                                             parse: parse,
                                             row_key_value_callback: row_key_value_callback,
                                             debug_verbose: debug_verbose )
  end

  def resend
    debug_verbose = email_dashboard_controller_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> resend <<<",
                                           "params=#{params}",
                                           "params[:begin_date]=#{params[:begin_date]}",
                                           "params[:end_date]=#{params[:end_date]}",
                                           "" ] if debug_verbose
    @begin_date = ViewHelper.to_date(params[:begin_date])
    @begin_date ||= Date.today - 1.week
    @end_date = ViewHelper.to_date(params[:end_date])
    @end_date ||= Date.tomorrow
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@begin_date=#{@begin_date}",
                                           "@end_date=#{@end_date}",
                                           "" ] if debug_verbose
    parms = []
    parms << "begin_date=#{begin_date_parm}"
    parms << "end_date=#{end_date_parm}"
    if resend_email_from_log_entry( debug_verbose: debug_verbose )
      redirect_to "/data/email_dashboard?#{parms.join('&')}", notice: 'Successfully resent email.'
    else
      redirect_to "/data/email_dashboard?#{parms.join('&')}", alert: 'Failed to resend email.'
    end
  end

  def resend_email_from_log_entry( debug_verbose: email_dashboard_controller_debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:begin_date]=#{params[:begin_date]}",
                                           "params[:end_date]=#{params[:end_date]}",
                                           "params[:event]=#{params[:event]}",
                                           "params[:id]=#{params[:id]}",
                                           "params[:timestamp]=#{params[:timestamp]}",
                                           "" ] if debug_verbose
    resend_log_entry = find_resend_log_entry( debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "resend_log_entry=#{resend_log_entry}",
                                           "" ] if debug_verbose
    return false unless resend_log_entry.present?
    entry = resend_log_entry
    # { timestamp: timestamp, event: event, event_note: event_note, class_name: class_name, id: id,
    #  raw_key_values: raw_key_values, line_number: line_number, parse_error: nil }
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> resend log entry found <<<",
                                           "entry=#{entry}",
                                           "entry.class.name=#{entry.class.name}",
                                           "entry[:timestamp]=#{entry[:timestamp]}",
                                           "entry[:event]=#{entry[:event]}",
                                           "entry[:event_note]=#{entry[:event_note]}",
                                           "entry[:class_name]=#{entry[:class_name]}",
                                           "entry[:id]=#{entry[:id]}",
                                           "entry[:raw_key_values].class.name=#{entry[:raw_key_values].class.name}",
                                           "entry[:line_number]=#{entry[:line_number]}",
                                           "entry[:parse_error]=#{entry[:parse_error]}",
                                           "" ] if debug_verbose
    key_values = JSON.parse(entry[:raw_key_values])
    resend_class_name = entry[:class_name]
    prior_timestamp = entry[:timestamp]
    resend_event = entry[:event]
    resend_event_note = entry[:event_event]
    resend_id = entry[:id]
    resend_current_user = key_values['current_user']
    resend_content_type = key_values['content_type']
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> resend log entry found <<<",
                                           "key_values.class.name=#{key_values.class.name}",
                                           "key_values=#{entry[:raw_key_values]}",
                                           "resend_class_name=#{resend_class_name}",
                                           "prior_timestamp=#{prior_timestamp}",
                                           "resend_current_user=#{resend_current_user}",
                                           "resend_id=#{resend_id}",
                                           "key_values['to']=#{key_values['to']}",
                                           "key_values['from']=#{key_values['from']}",
                                           "key_values['subject']=#{key_values['subject']}",
                                           "key_values['body']=#{key_values['body']}",
                                           "key_values['body'].class.name=#{key_values['body'].class.name}",
                                           "key_values['body']&.size=#{key_values['body']&.size}",
                                           "" ] if debug_verbose
    # resend_log_entry.each_with_index do |entry,index|
    #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                          ::Deepblue::LoggingHelper.called_from,
    #                                          ">>> resend log entry entry <<<",
    #                                          "index=#{index}",
    #                                          "entry=#{entry}",
    #                                          "entry.class.name=#{entry.class.name}",
    #                                          "params[:begin_date]=#{params[:begin_date]}",
    #                                          "" ] if debug_verbose
    # end
    resend_to = key_values['to']
    resend_from = key_values['from']
    resend_subject = key_values['subject']
    resend_body = key_values['body']
    resend_content_type = ::Deepblue::EmailHelper.detect_content_type( resend_body ) if resend_content_type.blank?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "resend_content_type=#{resend_content_type}",
                                           "resend_current_user=#{resend_current_user}",
                                           "resend_to=#{resend_to}",
                                           "resend_from=#{resend_from}",
                                           "resend_subject=#{resend_subject}",
                                           "resend_body=#{resend_body}",
                                           "" ] if debug_verbose
    # email_sent = false
    email_sent = ::Deepblue::EmailHelper.send_email( to: resend_to,
                                                     from: resend_from,
                                                     subject: resend_subject,
                                                     body: resend_body,
                                                     content_type: resend_content_type )
    ::Deepblue::EmailHelper.log( class_name: resend_class_name,
                                 current_user: resend_current_user,
                                 event: resend_event,
                                 event_note: resend_event_note,
                                 id: resend_id,
                                 to: resend_to,
                                 from: resend_from,
                                 subject: resend_subject,
                                 body: resend_body,
                                 content_type: resend_content_type,
                                 email_sent: email_sent,
                                 prior_timestamp: prior_timestamp,
                                 email_resend: true )
    return email_sent
  end

  def show
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> show <<<",
                                           "params=#{params}",
                                           "params[:begin_date]=#{params[:begin_date]}",
                                           "params[:end_date]=#{params[:end_date]}",
                                           "" ] if email_dashboard_controller_debug_verbose
    @begin_date = ViewHelper.to_date(params[:begin_date])
    @begin_date ||= Date.today - 1.week
    @end_date = ViewHelper.to_date(params[:end_date])
    @end_date ||= Date.tomorrow
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@begin_date=#{@begin_date}",
                                           "@end_date=#{@end_date}",
                                           "" ] if email_dashboard_controller_debug_verbose
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'hyrax/dashboard/show_email_dashboard'
  end

end
