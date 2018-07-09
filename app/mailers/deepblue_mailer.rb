# frozen_string_literal: true

class DeepblueMailer < ApplicationMailer
  default from: Deepblue::EmailHelper.notification_email

  layout "mailer.html"

  def send_an_email( to:, from:, subject:, body: )
    mail( to: to, from: from, subject: subject, body: body )
  end

end
