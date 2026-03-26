# frozen_string_literal: true

class DeepblueMailer < ApplicationMailer
  default from: Deepblue::EmailHelper.notification_email_from

  mattr_accessor :deepblue_mailer_debug_verbose, default: false

  layout "mailer.html"

  def self.send_an_email( to:, cc: nil, bcc: nil, from:, subject:, body:, content_type: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "" ] if  deepblue_mailer_debug_verbose
                                           # "" ] + caller_locations(0,30) if deepblue_mailer_debug_verbose
    if content_type.present?
      msg = ActionMailer::Base.mail( { to: to, cc: cc, bcc: bcc, from: from, subject: subject, body: body, content_type: content_type } )
    else
      msg = ActionMailer::Base.mail( { to: to, cc: cc, bcc: bcc, from: from, subject: subject, body: body } )
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "about send msg=#{msg.pretty_inspect}",
                                           "" ] if  deepblue_mailer_debug_verbose
    rv = msg.deliver
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "sent msg=#{msg.pretty_inspect}",
                                           "" ] if deepblue_mailer_debug_verbose
    rv
  end

  def self.send_an_email_html( to:, cc: nil, bcc: nil, from:, subject:, body: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "" ] if  deepblue_mailer_debug_verbose
                                           # "" ] + caller_locations(0,30) if deepblue_mailer_debug_verbose
    ActionMailer::Base.mail( to: to,
          cc: cc,
          bcc: bcc,
          from: from,
          body: body,
          content_type: ::Deepblue::EmailHelper::TEXT_HTML,
          subject: subject ).deliver
  end

end
