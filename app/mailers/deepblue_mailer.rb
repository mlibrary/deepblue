# frozen_string_literal: true

class DeepblueMailer < ApplicationMailer
  default from: Deepblue::EmailHelper.notification_email

  layout "mailer.html"

  def send_an_email( to:, cc: nil, bcc: nil, from:, subject:, body:, content_type: nil )
    if content_type.present?
      mail( to: to, cc: cc, bcc: bcc, from: from, subject: subject, body: body, content_type: content_type )
    else
      mail( to: to, cc: cc, bcc: bcc, from: from, subject: subject, body: body )
    end
  end

  def send_an_email_html( to:, cc: nil, bcc: nil, from:, subject:, body: )
    mail( to: to, cc: cc, bcc: bcc, from: from, body: body, content_type: "text/html", subject: subject )
  end

end
