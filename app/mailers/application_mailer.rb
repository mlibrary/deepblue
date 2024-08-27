# frozen_string_literal: true
# Reviewed: heliotrope

class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'
end
