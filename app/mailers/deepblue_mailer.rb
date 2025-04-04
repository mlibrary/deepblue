# frozen_string_literal: true

class DeepblueMailer < ApplicationMailer
  default from: Deepblue::EmailHelper.notification_email_from

  layout "mailer.html"

  def self.send_an_email( to:, cc: nil, bcc: nil, from:, subject:, body:, content_type: nil )
    if content_type.present?
      ActionMailer::Base.mail( { to: to, cc: cc, bcc: bcc, from: from, subject: subject, body: body, content_type: content_type } ).deliver
    else
      ActionMailer::Base.mail( { to: to, cc: cc, bcc: bcc, from: from, subject: subject, body: body } ).deliver
    end
  end

  def self.send_an_email_html( to:, cc: nil, bcc: nil, from:, subject:, body: )
    ActionMailer::Base.mail( to: to,
          cc: cc,
          bcc: bcc,
          from: from,
          body: body,
          content_type: ::Deepblue::EmailHelper::TEXT_HTML,
          subject: subject ).deliver
  end

end
