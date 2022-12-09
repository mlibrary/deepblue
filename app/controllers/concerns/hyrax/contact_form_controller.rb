# frozen_string_literal: true

module Hyrax

  class ContactFormController < ApplicationController
    class Status

      attr_accessor :akismet_used
      attr_accessor :akismet_check_rv_is_spam
      attr_accessor :akismet_check_rv_is_blatant
      attr_accessor :akismet_is_spam
      attr_accessor :antispam_delta_in_seconds
      attr_accessor :antispam_timestamp
      attr_accessor :contact_form_valid
      attr_accessor :create_timestamp
      attr_accessor :email_passthrough
      attr_accessor :ngr_details
      attr_accessor :ngr_humanity_details
      attr_accessor :ngr_is_human
      attr_accessor :ngr_minimum_score
      attr_accessor :ngr_used
      attr_accessor :referrer_ip
      attr_accessor :spam_status_unknown

      def initialize
        @akismet_is_spam = false
        @akismet_check_rv_is_spam = false
        @akismet_check_rv_is_blatant = false
        @akismet_used = false
        @antispam_delta_in_seconds = nil
        @antispam_timestamp = nil
        @contact_form_valid = nil
        @create_timestamp = nil
        @email_passthrough = nil
        @ngr_details = false
        @ngr_humanity_details = nil
        @ngr_is_human = nil # assume this is true and allow google recaptcha to set it to false as necessary
        @ngr_minimum_score = nil
        @ngr_used = false
        @referrer_ip = nil
        @spam_status_unknown = true
      end

      def antispam_delta_in_seconds
        @antispam_delta_in_seconds ||= @create_timestamp - @antispam_timestamp.to_i
      end

      def to_hash( msg_handler: nil )
        msgs = nil
        msgs = msg_handler.msg_queue.dup if msg_handler.present? && !msg_handler.msg_queue.nil?
        rv = { akismet_enabled: ::Hyrax::ContactFormController.akismet_enabled,
               akismet_is_spam: akismet_is_spam,
               akismet_check_rv_is_spam: akismet_check_rv_is_spam,
               akismet_check_rv_is_blatant: akismet_check_rv_is_blatant,
               akismet_used: akismet_used,
               antispam_delta_in_seconds: antispam_delta_in_seconds,
               antispam_timeout_in_seconds: ::Hyrax::ContactFormController.antispam_timeout_in_seconds,
               contact_form_email_passthrough_enabled: ::Hyrax::ContactFormController.contact_form_email_passthrough_enabled,
               contact_form_send_email: ::Hyrax::ContactFormController.contact_form_send_email,
               contact_form_valid: contact_form_valid,
               create_timestamp: create_timestamp,
               email_passthrough: email_passthrough,
               ngr_enabled: ::Hyrax::ContactFormController.ngr_enabled,
               ngr_humanity_details: ngr_humanity_details,
               ngr_is_human: ngr_is_human,
               ngr_just_human_test: ::Hyrax::ContactFormController.ngr_just_human_test,
               ngr_minimum_score: ngr_minimum_score,
               ngr_used: ngr_used,
               referrer_ip: referrer_ip,
               spam_status_unknown: spam_status_unknown,
               messages: msgs }
        # TODO: append messages if they exist
        return rv
      end
    end

    mattr_accessor :mattr_contact_form_controller_debug_verbose,
                   default: ContactFormIntegrationService.contact_form_controller_debug_verbose

    mattr_accessor :mattr_contact_form_send_email, default: ContactFormIntegrationService.contact_form_send_email

    mattr_accessor :contact_form_index_path, default: '/data/contact'
    mattr_accessor :contact_form_log_delivered, default: ContactFormIntegrationService.contact_form_log_delivered
    mattr_accessor :contact_form_log_spam, default: ContactFormIntegrationService.contact_form_log_spam
    mattr_accessor :antispam_timeout_in_seconds, default: ContactFormIntegrationService.antispam_timeout_in_seconds

    mattr_accessor :contact_form_email_passthrough_re,
                   default: ContactFormIntegrationService.contact_form_email_passthrough_re
    mattr_accessor :mattr_contact_form_email_passthrough_enabled,
                   default: ContactFormIntegrationService.contact_form_email_passthrough_enabled

    mattr_accessor :mattr_akismet_enabled, default: ContactFormIntegrationService.akismet_enabled
    mattr_accessor :akismet_env_slice_keys, default: ContactFormIntegrationService.akismet_env_slice_keys
    mattr_accessor :akismet_is_spam_only_if_blatant,
                   default: ContactFormIntegrationService.akismet_is_spam_only_if_blatant

    mattr_accessor :mattr_ngr_enabled, default: ContactFormIntegrationService.new_google_recaptcha_enabled
    mattr_accessor :ngr_just_human_test, default: ContactFormIntegrationService.new_google_recaptcha_just_human_test

    def self.akismet_enabled
      if Rails.env.production? && ::Deepblue::CacheService.cache_available?
        ::Deepblue::CacheService.var_cache_fetch( klass: ContactFormDashboardController,
                                                  var: :akismet_enabled,
                                                  default_value: mattr_akismet_enabled )
      else
        mattr_akismet_enabled
      end
    end

    def self.akismet_enabled=(value)
      if Rails.env.production? && ::Deepblue::CacheService.cache_available?
        ::Deepblue::CacheService.var_cache_write( klass: ContactFormDashboardController,
                                                  var: :akismet_enabled,
                                                  value: value )
      else
        ContactFormController.mattr_akismet_enabled = value
      end
    end

    def self.contact_form_controller_debug_verbose
      if Rails.env.production? && ::Deepblue::CacheService.cache_available?
        ::Deepblue::CacheService.var_cache_fetch( klass: ContactFormDashboardController,
                                                  var: :contact_form_controller_debug_verbose,
                                                  default_value: mattr_contact_form_controller_debug_verbose )
      else
        mattr_contact_form_controller_debug_verbose
      end
    end

    def self.contact_form_controller_debug_verbose=(value)
      if Rails.env.production? && ::Deepblue::CacheService.cache_available?
        ::Deepblue::CacheService.var_cache_write( klass: ContactFormDashboardController,
                                                  var: :contact_form_controller_debug_verbose,
                                                  value: value )
      else
        ContactFormController.mattr_contact_form_controller_debug_verbose = value
      end
    end

    def self.contact_form_email_passthrough_enabled
      if Rails.env.production? && ::Deepblue::CacheService.cache_available?
        ::Deepblue::CacheService.var_cache_fetch( klass: ContactFormDashboardController,
                                                  var: :contact_form_email_passthrough_enabled,
                                                  default_value: mattr_contact_form_controller_debug_verbose )
      else
        mattr_contact_form_email_passthrough_enabled
      end
    end

    def self.contact_form_email_passthrough_enabled=(value)
      if Rails.env.production? && ::Deepblue::CacheService.cache_available?
        ::Deepblue::CacheService.var_cache_write( klass: ContactFormDashboardController,
                                                  var: :contact_form_email_passthrough_enabled,
                                                  value: value )
      else
        ContactFormController.mattr_contact_form_email_passthrough_enabled = value
      end
    end

    def self.contact_form_send_email
      if Rails.env.production? && ::Deepblue::CacheService.cache_available?
        ::Deepblue::CacheService.var_cache_fetch( klass: ContactFormDashboardController,
                                                  var: :contact_form_send_email,
                                                  default_value: mattr_contact_form_send_email )
      else
        mattr_contact_form_send_email
      end
    end

    def self.contact_form_send_email=(value)
      if Rails.env.production? && ::Deepblue::CacheService.cache_available?
        ::Deepblue::CacheService.var_cache_write( klass: ContactFormDashboardController,
                                                  var: :contact_form_send_email,
                                                  value: value )
      else
        ContactFormController.mattr_contact_form_send_email = value
      end
    end

    def self.ngr_enabled
      if Rails.env.production? && ::Deepblue::CacheService.cache_available?
        ::Deepblue::CacheService.var_cache_fetch( klass: ContactFormDashboardController,
                                                  var: :ngr_enabled,
                                                  default_value: mattr_ngr_enabled )
      else
        mattr_ngr_enabled
      end
    end

    def self.ngr_enabled=(value)
      if Rails.env.production? && ::Deepblue::CacheService.cache_available?
        ::Deepblue::CacheService.var_cache_write( klass: ContactFormDashboardController,
                                                  var: :ngr_enabled,
                                                  value: value )
      else
        ContactFormController.mattr_ngr_enabled = value
      end
    end

    # NOTE: the save a timestamp of the first visit to the contact form to the session, then use to measure the
    # time spent on the contact form. If it is short, as determined by the configuration, currently defaulting
    # to 5 seconds, then it is probably spam

    # before_action :build_contact_form
    before_action :initialize_variables
    before_action :add_antispam_timestamp_to_session

    layout 'homepage'

    attr_accessor :msg_handler
    attr_accessor :status

    def initialize_variables
      @msg_handler = ::Deepblue::MessageHandler.new( debug_verbose: contact_form_controller_debug_verbose )
      @status = Status.new
      @contact_form = ::Hyrax::ContactForm.new(contact_form_params)
    end

    def add_antispam_timestamp_to_session
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "antispam_timestamp=#{antispam_timestamp}",
                               "" ] if contact_form_controller_debug_verbose
      if antispam_timestamp.blank?
        antispam_timestamp = Time.now.to_i
      end
      status.antispam_timestamp = antispam_timestamp
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "antispam_timestamp=#{antispam_timestamp}",
                               "" ] if contact_form_controller_debug_verbose
    end

    # Override this method if you want to perform additional operations
    # when a email is successfully sent, such as sending a confirmation
    # response to the user.
    def after_deliver
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "create_timestamp=#{status.create_timestamp}",
                               "antispam_timestamp=#{status.antispam_timestamp}",
                               "antispam_delta_in_seconds=#{status.antispam_delta_in_seconds}",
                               "is_spam?=#{is_spam?}",
                               "" ] if contact_form_controller_debug_verbose
      if is_spam?
        if is_antispam_delta_under_timeout?
          # TODO: move this to LoggingHelper
          Rails.logger.warn "Possible spam from IP #{status.referrer_ip}. " +
                              "Antispam threshold seconds #{status.antispam_delta_in_seconds} is less than #{antispam_timeout_in_seconds}"
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

    def akismet_enabled
      ContactFormController.akismet_enabled
    end

    # def antispam_delta_in_seconds
    #   @antispam_delta_in_seconds ||= status.create_timestamp - antispam_timestamp.to_i
    # end

    def contact_form_controller_debug_verbose
      ContactFormController.contact_form_controller_debug_verbose
    end

    def contact_form_email_passthrough_enabled
      ContactFormController.contact_form_email_passthrough_enabled
    end

    def contact_form_params
      return {} unless params.key?(:contact_form)
      params.require(:contact_form).permit(:contact_method, :category, :name, :email, :subject, :message)
    end

    def contact_form_send_email
      ContactFormController.contact_form_send_email
    end

    def create
      status.create_timestamp = Time.now.to_i
      status.contact_form_valid = @contact_form.valid?
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "@contact_form.valid?=#{@contact_form.valid?}",
                               "" ] if contact_form_controller_debug_verbose
      if @contact_form.valid?
        env = request.env
        status.referrer_ip = env['action_dispatch.remote_ip'].to_s
        msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "@contact_form.valid?=#{@contact_form.valid?}",
                                 "@contact_form.spam?=#{@contact_form.spam?}",
                                 "request.class.name=#{request.class.name}",
                                 "env.class.name=#{env.class.name}",
                                 "env.keys=#{env.keys}",
                                 "env['REMOTE_ADDR']=#{env['REMOTE_ADDR']}",
                                 "env['REQUEST_URI']=#{env['REQUEST_URI']}",
                                 "env['HTTP_USER_AGENT']=#{env['HTTP_USER_AGENT']}",
                                 "referrer_ip=#{status.referrer_ip}",
                                 # "env=#{env}",
                                 "akismet_env_vars=#{akismet_env_vars}",
                                 "params[:action]=#{params[:action]}",
                                 "contact_form_index_path=#{contact_form_index_path}",
                                 "create_timestamp=#{status.create_timestamp}",
                                 "antispam_timestamp=#{antispam_timestamp}",
                                 "antispam_delta_in_seconds=#{status.antispam_delta_in_seconds}",
                                 "is_spam?=#{is_spam?}",
                                 "params=#{params}",
                                 "contact_form_send_email=#{contact_form_send_email}",
                                 "akismet_enabled=#{akismet_enabled}",
                                 "ngr_enabled=#{ngr_enabled}",
                                 "spam_status_unknown=#{status.spam_status_unknown}",
                                 "" ] if contact_form_controller_debug_verbose
        email_passthrough?
        akismet_is_spam? if status.spam_status_unknown && akismet_enabled
        new_google_recaptcha if status.spam_status_unknown && ngr_enabled
        msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "is_spam?=#{is_spam?}",
                                 "" ] if contact_form_controller_debug_verbose
        if contact_form_send_email
          ::Hyrax::ContactMailer.contact(@contact_form).deliver_now unless is_spam?
        end
        msg = 'Thank you for your message!' # TODO: localize
        msg_handler.msg msg
        flash.now[:notice] = msg
        after_deliver
        @contact_form = ContactForm.new
      else
        msg = 'Sorry, this message was not sent successfully. ' +
          @contact_form.errors.full_messages.map(&:to_s).join(", ")
        msg_handler.msg msg
        flash.now[:error] = msg
        after_error
      end
      render :new
    rescue RuntimeError => exception
      handle_create_exception(exception)
    end

    def handle_create_exception(exception)
      msg_handler.bold_error("Contact form failed to send: #{exception.inspect}")
      flash.now[:error] = 'Sorry, this message was not delivered.' # TODO: localize
      render :new
    end

    def log( event:, contact_method:, category:, name:, email:, subject:, message: )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               # "akismet_enabled=#{akismet_enabled}",
                               # "akismet_used=#{status.akismet_used}",
                               # "ngr_enabled=#{ngr_enabled}",
                               # "ngr_used=#{status.ngr_used}",
                               # "email_passthrough=#{status.email_passthrough}",
                               # "event=#{event}",
                               # "contact_method=#{contact_method}",
                               # "category=#{category}",
                               # "name=#{name}",
                               # "email=#{email}",
                               # "subject=#{subject}",
                               # "message=#{message}",
                               # "referrer_ip=#{status.referrer_ip}",
                               # "antispam_delta_in_seconds=#{status.antispam_delta_in_seconds}",
                               # "antispam_timeout_in_seconds=#{antispam_timeout_in_seconds}",
                               # "contact_form_send_email=#{contact_form_send_email}",
                               "" ] if contact_form_controller_debug_verbose
      log_key_values = {}.merge( contact_method: contact_method,
                                 category: category,
                                 name: name,
                                 email: email,
                                 subject: subject,
                                 message: message )
      # if contact_form_email_passthrough_enabled && status.email_passthrough.present?
      #   log_key_values.merge!( email_passthrough: status.email_passthrough )
      # end
      # if akismet_enabled && contact_form_controller_debug_verbose
      #   log_key_values.merge!( akismet_enabled: akismet_enabled, akismet_used: status.akismet_used )
      #   msg_handler.bold_debug [ msg_handler.here,
      #                                          msg_handler.called_from,
      #                                          "akismet_enabled=#{akismet_enabled}",
      #                                          "" ] if contact_form_controller_debug_verbose
      # end
      # if status.akismet_used
      #   msg_handler.bold_debug [ msg_handler.here,
      #                                          msg_handler.called_from,
      #                                          "akismet_is_spam=#{status.akismet_is_spam}",
      #                                          "akismet_check_rv_is_spam=#{status.akismet_check_rv_is_spam}",
      #                                          "akismet_check_rv_is_blatant=#{status.akismet_check_rv_is_blatant}",
      #                                          "" ] if contact_form_controller_debug_verbose
      #   log_key_values.merge!( akismet_is_spam: status.akismet_is_spam,
      #                          akismet_check_rv_is_spam: status.akismet_check_rv_is_spam,
      #                          akismet_check_rv_is_blatant: status.akismet_check_rv_is_blatant )
      # end
      # if ngr_enabled && contact_form_controller_debug_verbose
      #   log_key_values.merge!( ngr_enabled: ngr_enabled, ngr_used: status.ngr_used )
      #   msg_handler.bold_debug [ msg_handler.here,
      #                                          msg_handler.called_from,
      #                                          "ngr_enabled=#{ngr_enabled}",
      #                                          "ngr_humanity_details.present?=#{status.ngr_humanity_details.present?}",
      #                                          "" ] if contact_form_controller_debug_verbose
      # end
      # if status.ngr_used
      #   unless status.ngr_humanity_details.present?
      #     msg_handler.bold_debug [ msg_handler.here,
      #                              msg_handler.called_from,
      #                              "ngr_minimum_score=#{NewGoogleRecaptcha.minimum_score}",
      #                              "ngr_is_human=#{status.ngr_is_human}",
      #                              "" ] if contact_form_controller_debug_verbose
      #     log_key_values.merge!( ngr_minimum_score: NewGoogleRecaptcha.minimum_score,
      #                            ngr_is_human: status.ngr_is_human )
      #   else
      #     msg_handler.bold_debug [ msg_handler.here,
      #                              msg_handler.called_from,
      #                              "ngr_humanity_details_is_human=#{status.ngr_humanity_details[:is_human]}",
      #                              "ngr_humanity_score=#{status.ngr_humanity_details[:score]}",
      #                              "ngr_minimum_score=#{NewGoogleRecaptcha.minimum_score}",
      #                              "ngr_is_human=#{status.ngr_is_human}",
      #                              "" ] if contact_form_controller_debug_verbose
      #     log_key_values.merge!( ngr_humanity_details_is_human: status.ngr_humanity_details[:is_human],
      #                            ngr_humanity_score: status.ngr_humanity_details[:score],
      #                            ngr_minimum_score: NewGoogleRecaptcha.minimum_score,
      #                            ngr_is_human: status.ngr_is_human )
      #   end
      # end
      # unless contact_form_send_email
      #   msg_handler.bold_debug [ msg_handler.here,
      #                            msg_handler.called_from,
      #                            "contact_form_send_email=#{contact_form_send_email}",
      #                            "" ] if contact_form_controller_debug_verbose
      #   log_key_values.merge!( contact_form_send_email: contact_form_send_email )
      # end
      status.ngr_minimum_score = NewGoogleRecaptcha.minimum_score if status.ngr_used
      status.ngr_humanity_details_is_human = status.ngr_humanity_details[:is_human] if status.ngr_used && status.ngr_humanity_details.present?
      log_key_values.merge! status.to_hash
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "log_key_values=",
                               log_key_values,
                               "" ] if contact_form_controller_debug_verbose
      ContactFormHelper.log( class_name: self.class.name,
                            event: event,
                            echo_to_rails_logger: false,
                            contact_method: contact_method,
                            category: category,
                            name: name,
                            email: email,
                            subject: subject,
                            message: message,
                            **log_key_values )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
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

    def new
      url = params[:url]
      @contact_form.message = t('data_set.contact_message_header') + "\n" +
                              t('data_set.contact_message_title') + params[:title] + "\n"  +
                              t('data_set.contact_message_creator') + params[:author] + "\n" +
                              t('data_set.contact_message_url') + url + "\n" unless url.nil?
    end

    def ngr_enabled
      ContactFormController.ngr_enabled
    end

    def akismet_env_vars
      request.env.slice(*akismet_env_slice_keys)
    end

    def akismet_is_spam?
      msg_handler.bold_debug [ msg_handler.here,
                                             msg_handler.called_from,
                                             "" ] if contact_form_controller_debug_verbose
      return unless status.spam_status_unknown
      ContactFormIntegrationService.akismet_setup
      #   name: @contact_form.name,
      #   email: @contact_form.email,
      #   subject: @contact_form.subject,
      #   message: @contact_form.message

      # see: https://akismet.com/development/api/#comment-check
      # category: @contact_form.category,
      akismet_params = {
        # blog: Rails.configuration.hostname, # invalid param name
        type: 'contact-form',
        text: URI.encode_www_form_component( @contact_form.message ), # replace URI.escape
        created_at: status.create_timestamp,
        author: URI.encode_www_form_component( @contact_form.name ),
        author_email: URI.encode_www_form_component( @contact_form.email ),
        # author_url: 'http://geocities.com/eldont',
        # post_url: 'http://example.com/posts/1',
        # honeypot_field_name: 'contact_method', # invalid param name
        # hidden_honeypot_field: URI.encode_www_form_component( @contact_form.contact_method ), # invalid param name
        referrer: request.env['HTTP_REFERER'],
        env: akismet_env_vars
      }
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "akismet_params=",
                               akismet_params,
                               "" ] if contact_form_controller_debug_verbose

      begin
        # status.akismet_is_spam = Akismet.spam?(request.ip, request.user_agent, akismet_params)
        status.akismet_check_rv_is_spam, status.akismet_check_rv_is_blatant = Akismet.check( request.ip,
                                                                                 request.user_agent,
                                                                                 akismet_params )
        status.akismet_is_spam = if akismet_is_spam_only_if_blatant
                             ( status.akismet_check_rv_is_spam && status.akismet_check_rv_is_blatant )
                           else
                             ( status.akismet_check_rv_is_spam || status.akismet_check_rv_is_blatant )
                           end
        status.akismet_used = true
        status.spam_status_unknown = false
      rescue => e
        Rails.logger.error("Unable to connect to Akismet: #{e}, skipping check")
        status.akismet_is_spam = nil
        status.akismet_check_rv_is_spam = nil
        status.akismet_check_rv_is_blatant = nil
        status.akismet_used = false
      end
    end

    def email_passthrough?
      return false unless contact_form_email_passthrough_enabled
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "spam_status_unknown=#{status.spam_status_unknown}",
                               "@contact_form.email=#{@contact_form.email}",
                               "email_passthrough=#{status.email_passthrough}",
                               "" ] if contact_form_controller_debug_verbose
      return false unless status.spam_status_unknown
      begin
        email = @contact_form.email
        return false unless email =~ contact_form_email_passthrough_re
        msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "email #{email} matched #{contact_form_email_passthrough_re}",
                                 "" ] if contact_form_controller_debug_verbose
        status.spam_status_unknown = false
        status.email_passthrough = email
        return true
      end
    end

    def is_antispam_delta_under_timeout?
      status.antispam_delta_in_seconds < antispam_timeout_in_seconds
    end

    def is_spam?
      return false if status.email_passthrough.present?
      if akismet_enabled
        unless status.spam_status_unknown
          return status.akismet_is_spam
        end
      end
      if ngr_enabled
        unless status.spam_status_unknown
          return !status.ngr_is_human
        end
      end
      return true if @contact_form.spam?
      return true if is_antispam_delta_under_timeout?
      return false
    end

    def new_google_recaptcha
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "" ] if contact_form_controller_debug_verbose
      return unless status.spam_status_unknown
      begin
        msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "params=#{params}",
                                 "NewGoogleRecaptcha.minimum_score=#{NewGoogleRecaptcha.minimum_score}",
                                 "" ] if contact_form_controller_debug_verbose
        msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "" ] if contact_form_controller_debug_verbose
        if ngr_just_human_test
          status.ngr_is_human = NewGoogleRecaptcha.human?( params[:new_google_recaptcha_token],
                                                     # hyrax.contact_form_index_path,
                                                     contact_form_index_path,
                                                     NewGoogleRecaptcha.minimum_score )
          msg_handler.bold_debug [ msg_handler.here,
                                   msg_handler.called_from,
                                   "ngr_is_human=#{status.ngr_is_human}" ] if contact_form_controller_debug_verbose
        else
          status.ngr_humanity_details = NewGoogleRecaptcha.get_humanity_detailed( params[:new_google_recaptcha_token],
                                                                            # hyrax.contact_form_index_path,
                                                                            contact_form_index_path,
                                                                            NewGoogleRecaptcha.minimum_score )
          status.ngr_is_human = NewGoogleRecaptcha.minimum_score <= status.ngr_humanity_details[:score]
          msg_handler.bold_debug [ msg_handler.here,
                                                 msg_handler.called_from,
                                                 "ngr_humanity_details=#{status.ngr_humanity_details}",
                                                 "ngr_humanity_details[:score]=#{status.ngr_humanity_details[:score]}",
                                                 "ngr_humanity_details[:is_human]=#{status.ngr_humanity_details[:is_human]}",
                                                 "NewGoogleRecaptcha.minimum_score=#{NewGoogleRecaptcha.minimum_score}",
                                                 "ngr_is_human=#{status.ngr_is_human}",
                                                 "" ] if contact_form_controller_debug_verbose
        end
        status.ngr_used = true
        status.spam_status_unknown = false
      rescue => e
        Rails.logger.error("Unable to connect to google: #{e}, skipping check")
        status.ngr_is_human = nil
        status.ngr_humanity_details = nil
        status.ngr_used = false
      end
    end

  end

end
