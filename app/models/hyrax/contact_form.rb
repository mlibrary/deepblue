module Hyrax

  class ContactForm

    include ActiveModel::Model
    attr_accessor :contact_method, :category, :name, :email, :subject, :message
    validates :email, :category, :name, :subject, :message, presence: true
    validates :email, format: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i, allow_blank: true

    # - can't use this without ActiveRecord::Base validates_inclusion_of :category, in: self.class.issue_types_for_locale

    # They should not have filled out the `contact_method' field. That's there to prevent spam.
    def spam?
      contact_method.present?
    end

    # Declare the e-mail headers. It accepts anything the mail method
    # in ActionMailer accepts.
    def headers
      {
        subject: "#{Hyrax.config.subject_prefix} #{subject}",
        # to: Hyrax.config.contact_email,
        to: ::Deepblue::EmailHelper.notification_email_contact_form_to,
        from: email
      }
    end

    def self.issue_types_for_locale
      [
        I18n.t('hyrax.contact_form.issue_types.depositing'),
        I18n.t('hyrax.contact_form.issue_types.changing'),
        I18n.t('hyrax.contact_form.issue_types.browsing'),
        I18n.t('hyrax.contact_form.issue_types.reporting'),
        I18n.t('hyrax.contact_form.issue_types.general'),
        I18n.t( 'hyrax.contact_form.issue_types.size', max_upload_size: ::DeepBlueDocs::Application.config.upload_max_file_size_str )
      ]
    end

  end

end
