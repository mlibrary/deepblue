# frozen_string_literal: true

module Hyrax

  class ContactFormController < ApplicationController

    ALL_LOCAL = true # so new code isn't called

    # mattr_accessor :contact_form_controller_debug_verbose,
    #                default: ContactFormIntegrationService.contact_form_controller_debug_verbose
    #
    # mattr_accessor :contact_form_log_delivered, default: ContactFormIntegrationService.contact_form_log_delivered
    # mattr_accessor :contact_form_log_spam, default: ContactFormIntegrationService.contact_form_log_spam
    # mattr_accessor :antispam_timeout_in_seconds, default: ContactFormIntegrationService.antispam_timeout_in_seconds

    mattr_accessor :contact_form_controller_debug_verbose, default: true
    mattr_accessor :contact_form_log_delivered, default: true
    mattr_accessor :contact_form_log_spam, default: true
    mattr_accessor :antispam_timeout_in_seconds, default: 5
    # mattr_accessor :antispam_timeout_in_seconds, default: 5_000_000

    # NOTE: the save a timestamp of the first visit to the contact form to the session, then use to measure the
    # time spent on the contact form. If it is short, as determined by the configuration, currently defaulting
    # to 5 seconds, then it is probably spam

    before_action :build_contact_form
    before_action :add_antispam_timestamp_to_session

    layout 'homepage'

    def new; end

    def create
      @create_timestamp = Time.now.to_i
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@create_timestamp=#{@create_timestamp}",
                                             "antispam_timestamp=#{antispam_timestamp}",
                                             "antispam_delta_in_seconds=#{antispam_delta_in_seconds}",
                                             "is_spam?=#{is_spam?}",
                                             "params=#{params}",
                                             "@contact_form.valid?=#{@contact_form.valid?}",
                                             "@contact_form.spam?=#{@contact_form.spam?}",
                                             "" ] if contact_form_controller_debug_verbose
      if @contact_form.valid?
        ContactMailer.contact(@contact_form).deliver_now unless is_spam?
        flash.now[:notice] = 'Thank you for your message!' # TODO: localize
        after_deliver
        @contact_form = ContactForm.new
      else
        flash.now[:error] = 'Sorry, this message was not sent successfully. ' +
          @contact_form.errors.full_messages.map(&:to_s).join(", ")
        after_error
      end
      render :new
    rescue RuntimeError => exception
      handle_create_exception(exception)
    end

    def handle_create_exception(exception)
      ::Deepblue::LoggingHelper.bold_error("Contact form failed to send: #{exception.inspect}")
      flash.now[:error] = 'Sorry, this message was not delivered.' # TODO: localize
      render :new
    end

    # Override this method if you want to perform additional operations
    # when a email is successfully sent, such as sending a confirmation
    # response to the user.
    def after_deliver
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@create_timestamp=#{@create_timestamp}",
                                             "antispam_timestamp=#{antispam_timestamp}",
                                             "antispam_delta_in_seconds=#{antispam_delta_in_seconds}",
                                             "is_spam?=#{is_spam?}",
                                             "" ] if contact_form_controller_debug_verbose
      if is_spam?
        if is_antispam_delta_under_timeout?
          # TODO: move this to LoggingHelper
          Rails.logger.warn "Possible spam from IP #{request.env['REMOTE_ADDR']}. " +
                              "Antispam threshold seconds #{antispam_delta_in_seconds} is less than #{antispam_timeout_in_seconds}"
        end
        log( event: 'spam',
             contact_method: @contact_form.contact_method,
             category: @contact_form.category,
             name: @contact_form.name,
             email: @contact_form.email,
             subject: @contact_form.subject,
             message: @contact_form.message ) if contact_form_log_spam
      else
        log( event: 'delivered',
             contact_method: @contact_form.contact_method,
             category: @contact_form.category,
             name: @contact_form.name,
             email: @contact_form.email,
             subject: @contact_form.subject,
             message: @contact_form.message ) if contact_form_log_delivered
      end
    end

    def after_error
      # TODO
    end

    def antispam_delta_in_seconds
      @antispam_delta_in_seconds ||= @create_timestamp - antispam_timestamp.to_i
    end

    private

    def add_antispam_timestamp_to_session
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "antispam_timestamp=#{antispam_timestamp}",
                                             "" ] if contact_form_controller_debug_verbose
      if antispam_timestamp.blank?
        antispam_timestamp = Time.now.to_i
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "antispam_timestamp=#{antispam_timestamp}",
                                             "" ] if contact_form_controller_debug_verbose
    end

    def build_contact_form
      @contact_form = Hyrax::ContactForm.new(contact_form_params)
    end

    def contact_form_params
      return {} unless params.key?(:contact_form)
      params.require(:contact_form).permit(:contact_method, :category, :name, :email, :subject, :message)
    end

    def log( event:, contact_method:, category:, name:, email:, subject:, message: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ALL_LOCAL=#{ALL_LOCAL}",
                                             "event=#{event}",
                                             "contact_method=#{contact_method}",
                                             "category=#{category}",
                                             "name=#{name}",
                                             "email=#{email}",
                                             "subject=#{subject}",
                                             "message=#{message}",
                                             "request.env['REMOTE_ADDR']=#{request.env['REMOTE_ADDR']}",
                                             "antispam_delta_in_seconds=#{antispam_delta_in_seconds}",
                                             "antispam_timeout_in_seconds=#{antispam_timeout_in_seconds}",
                                             "" ] if contact_form_controller_debug_verbose
      unless ALL_LOCAL
        ContactFormHelper.log( class_name: self.class.name,
                               event: event,
                               contact_method: contact_method,
                               category: category,
                               name: name,
                               email: email,
                               subject: subject,
                               message: message,
                               remote_address:request.env['REMOTE_ADDR'],
                               antispam_delta_in_seconds: antispam_delta_in_seconds,
                               antispam_timeout_in_seconds: antispam_timeout_in_seconds )
      else
        log_key_values = {}.merge( contact_method: contact_method,
                                   category: category,
                                   name: name,
                                   email: email,
                                   subject: subject,
                                   message: message,
                                   remote_address:request.env['REMOTE_ADDR'],
                                   antispam_delta_in_seconds: antispam_delta_in_seconds,
                                   antispam_timeout_in_seconds: antispam_timeout_in_seconds )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "log_key_values=#{log_key_values}",
                                               "" ] if contact_form_controller_debug_verbose
        msg = ::Deepblue::LoggingHelper.msg_to_log( class_name: self.class.name,
                          event: event,
                          event_note: '',
                          id: 'N/A',
                          timestamp: ::Deepblue::LoggingHelper.timestamp_now,
                          time_zone: ::Deepblue::LoggingHelper.timestamp_zone,
                          **log_key_values )
        Rails.logger.info msg
      end
    end

    def is_antispam_delta_under_timeout?
      antispam_delta_in_seconds < antispam_timeout_in_seconds
    end

    def is_spam?
      return true if @contact_form.spam?
      return true if is_antispam_delta_under_timeout?
      return false
    end

  end

end
