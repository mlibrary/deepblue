# frozen_string_literal: true

module Hyrax

  class ContactFormController < ApplicationController

    mattr_accessor :contact_form_controller_debug_verbose,
                   default: ContactFormIntegrationService.contact_form_controller_debug_verbose

    mattr_accessor :contact_form_send_email, default: ContactFormIntegrationService.contact_form_send_email

    mattr_accessor :contact_form_index_path, default: '/data/contact'
    mattr_accessor :contact_form_log_delivered, default: ContactFormIntegrationService.contact_form_log_delivered
    mattr_accessor :contact_form_log_spam, default: ContactFormIntegrationService.contact_form_log_spam
    mattr_accessor :antispam_timeout_in_seconds, default: ContactFormIntegrationService.antispam_timeout_in_seconds

    mattr_accessor :akismet_enabled, default: ContactFormIntegrationService.akismet_enabled
    mattr_accessor :akismet_env_slice_keys, default: ContactFormIntegrationService.akismet_env_slice_keys

    mattr_accessor :ngr_enabled, default: ContactFormIntegrationService.new_google_recaptcha_enabled
    mattr_accessor :ngr_just_human_test, default: ContactFormIntegrationService.new_google_recaptcha_just_human_test

    # NOTE: the save a timestamp of the first visit to the contact form to the session, then use to measure the
    # time spent on the contact form. If it is short, as determined by the configuration, currently defaulting
    # to 5 seconds, then it is probably spam

    # before_action :build_contact_form
    before_action :initialize_variables
    before_action :add_antispam_timestamp_to_session

    layout 'homepage'

    def initialize_variables
      @spam_status_unknown = true
      @akismet_used = false
      @akismet_is_spam = false
      @akismet_is_blatant = false
      @ngr_used = false
      @ngr_is_human = nil # assume this is true and allow google recaptcha to set it to false as necessary
      @ngr_humanity_details = nil
      @contact_form = Hyrax::ContactForm.new(contact_form_params)
      @referrer_ip = nil
    end

    def new; end

    def create
      @create_timestamp = Time.now.to_i
      env = request.env
      @referrer_ip = env['action_dispatch.remote_ip'].to_s
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "request.class.name=#{request.class.name}",
                                             "env.class.name=#{env.class.name}",
                                             "env.keys=#{env.keys}",
                                             "env['REMOTE_ADDR']=#{env['REMOTE_ADDR']}",
                                             "env['REQUEST_URI']=#{env['REQUEST_URI']}",
                                             "env['HTTP_USER_AGENT']=#{env['HTTP_USER_AGENT']}",
                                             "@referrer_ip=#{@referrer_ip}",
                                             # "env=#{env}",
                                             "akismet_env_vars=#{akismet_env_vars}",
                                             "params[:action]=#{params[:action]}",
                                             "contact_form_index_path=#{contact_form_index_path}",
                                             "@create_timestamp=#{@create_timestamp}",
                                             "antispam_timestamp=#{antispam_timestamp}",
                                             "antispam_delta_in_seconds=#{antispam_delta_in_seconds}",
                                             "is_spam?=#{is_spam?}",
                                             "params=#{params}",
                                             "contact_form_send_email=#{contact_form_send_email}",
                                             "@contact_form.valid?=#{@contact_form.valid?}",
                                             "@contact_form.spam?=#{@contact_form.spam?}",
                                             "akismet_enabled=#{akismet_enabled}",
                                             "ngr_enabled=#{ngr_enabled}",
                                             "contact_form_send_email=#{contact_form_send_email}",
                                             "@spam_status_unknown=#{@spam_status_unknown}",
                                             "" ] if contact_form_controller_debug_verbose
      akismet_is_spam? if @spam_status_unknown && akismet_enabled
      new_google_recaptcha if @spam_status_unknown && ngr_enabled
      if @contact_form.valid?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "is_spam?=#{is_spam?}",
                                               "" ] if contact_form_controller_debug_verbose
        if contact_form_send_email
          ContactMailer.contact(@contact_form).deliver_now unless is_spam?
        end
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
          Rails.logger.warn "Possible spam from IP #{@referrer_ip}. " +
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

    def contact_form_params
      return {} unless params.key?(:contact_form)
      params.require(:contact_form).permit(:contact_method, :category, :name, :email, :subject, :message)
    end

    def log( event:, contact_method:, category:, name:, email:, subject:, message: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "akismet_enabled=#{akismet_enabled}",
                                             "@akismet_used=#{@akismet_used}",
                                             "ngr_enabled=#{ngr_enabled}",
                                             "@ngr_used=#{@ngr_used}",
                                             "event=#{event}",
                                             "contact_method=#{contact_method}",
                                             "category=#{category}",
                                             "name=#{name}",
                                             "email=#{email}",
                                             "subject=#{subject}",
                                             "message=#{message}",
                                             "@referrer_ip=#{@referrer_ip}",
                                             "antispam_delta_in_seconds=#{antispam_delta_in_seconds}",
                                             "antispam_timeout_in_seconds=#{antispam_timeout_in_seconds}",
                                             "contact_form_send_email=#{contact_form_send_email}",
                                             "" ] if contact_form_controller_debug_verbose
      log_key_values = {}.merge( contact_method: contact_method,
                                 category: category,
                                 name: name,
                                 email: email,
                                 subject: subject,
                                 message: message,
                                 referrer_ip: @referrer_ip,
                                 antispam_delta_in_seconds: antispam_delta_in_seconds,
                                 antispam_timeout_in_seconds: antispam_timeout_in_seconds )
      if akismet_enabled && contact_form_controller_debug_verbose
        log_key_values.merge!( akismet_enabled: akismet_enabled, akismet_used: @akismet_used )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "akismet_enabled=#{akismet_enabled}",
                                               "" ] if contact_form_controller_debug_verbose
      end
      if @akismet_used
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "@akismet_is_spam=#{@akismet_is_spam}",
                                               "@akismet_is_blatant=#{@akismet_is_blatant}",
                                               "" ] if contact_form_controller_debug_verbose
        log_key_values.merge!( akismet_is_spam: @akismet_is_spam,
                               akismet_is_blatant: @akismet_is_blatant )
      end
      if ngr_enabled && contact_form_controller_debug_verbose
        log_key_values.merge!( ngr_enabled: ngr_enabled, ngr_used: @ngr_used )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "ngr_enabled=#{ngr_enabled}",
                                               "@ngr_humanity_details.present?=#{@ngr_humanity_details.present?}",
                                               "" ] if contact_form_controller_debug_verbose
      end
      if @ngr_used
        unless @ngr_humanity_details.present?
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "ngr_minimum_score=#{NewGoogleRecaptcha.minimum_score}",
                                                 "ngr_is_human=#{@ngr_is_human}",
                                                 "" ] if contact_form_controller_debug_verbose
          log_key_values.merge!( ngr_minimum_score: NewGoogleRecaptcha.minimum_score,
                                 ngr_is_human: @ngr_is_human )
        else
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "ngr_humanity_details_is_human=#{@ngr_humanity_details[:is_human]}",
                                                 "ngr_humanity_score=#{@ngr_humanity_details[:score]}",
                                                 "ngr_minimum_score=#{NewGoogleRecaptcha.minimum_score}",
                                                 "ngr_is_human=#{@ngr_is_human}",
                                                 "" ] if contact_form_controller_debug_verbose
          log_key_values.merge!( ngr_humanity_details_is_human: @ngr_humanity_details[:is_human],
                                 ngr_humanity_score: @ngr_humanity_details[:score],
                                 ngr_minimum_score: NewGoogleRecaptcha.minimum_score,
                                 ngr_is_human: @ngr_is_human )
        end
      end
      unless contact_form_send_email
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "contact_form_send_email=#{contact_form_send_email}",
                                               "" ] if contact_form_controller_debug_verbose
        log_key_values.merge!( contact_form_send_email: contact_form_send_email )
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
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
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "log_key_values=#{log_key_values.to_s}",
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

    def akismet_env_vars
      request.env.slice(*akismet_env_slice_keys)
    end

    def akismet_is_spam?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if contact_form_controller_debug_verbose
      return unless @spam_status_unknown
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
        created_at: @create_timestamp,
        author: URI.encode_www_form_component( @contact_form.name ),
        author_email: URI.encode_www_form_component( @contact_form.email ),
        # author_url: 'http://geocities.com/eldont',
        # post_url: 'http://example.com/posts/1',
        # honeypot_field_name: 'contact_method', # invalid param name
        # hidden_honeypot_field: URI.encode_www_form_component( @contact_form.contact_method ), # invalid param name
        referrer: request.env['HTTP_REFERER'],
        env: akismet_env_vars
      }
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "akismet_params=",
                                             akismet_params,
                                             "" ] if contact_form_controller_debug_verbose

      begin
        # @akismet_is_spam = Akismet.spam?(request.ip, request.user_agent, akismet_params)
        @akismet_is_spam, @akismet_is_blatant = Akismet.check(request.ip, request.user_agent, akismet_params)
        @akismet_is_spam = ( @akismet_is_spam || @akismet_is_blatant )
        @akismet_used = true
        @spam_status_unknown = false
      rescue => e
        Rails.logger.error("Unable to connect to Akismet: #{e}, skipping check")
        @akismet_is_spam = nil
        @akismet_is_blatant = nil
        @akismet_used = false
      end
    end

    def is_antispam_delta_under_timeout?
      antispam_delta_in_seconds < antispam_timeout_in_seconds
    end

    def is_spam?
      if akismet_enabled
        unless @spam_status_unknown
          return @akismet_is_spam
        end
      end
      if ngr_enabled
        unless @spam_status_unknown
          return !@ngr_is_human
        end
      end
      return true if @contact_form.spam?
      return true if is_antispam_delta_under_timeout?
      return false
    end

    def new_google_recaptcha
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if contact_form_controller_debug_verbose
      return unless @spam_status_unknown
      begin
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "NewGoogleRecaptcha.minimum_score=#{NewGoogleRecaptcha.minimum_score}",
                                               "" ] if contact_form_controller_debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if contact_form_controller_debug_verbose
        if ngr_just_human_test
          @ngr_is_human = NewGoogleRecaptcha.human?( params[:new_google_recaptcha_token],
                                                     # hyrax.contact_form_index_path,
                                                     contact_form_index_path,
                                                     NewGoogleRecaptcha.minimum_score )
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@ngr_is_human=#{@ngr_is_human}" ] if contact_form_controller_debug_verbose
        else
          @ngr_humanity_details = NewGoogleRecaptcha.get_humanity_detailed( params[:new_google_recaptcha_token],
                                                                            # hyrax.contact_form_index_path,
                                                                            contact_form_index_path,
                                                                            NewGoogleRecaptcha.minimum_score )
          @ngr_is_human = NewGoogleRecaptcha.minimum_score <= @ngr_humanity_details[:score]
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@ngr_humanity_details=#{@ngr_humanity_details}",
                                                 "@ngr_humanity_details[:score]=#{@ngr_humanity_details[:score]}",
                                                 "@ngr_humanity_details[:is_human]=#{@ngr_humanity_details[:is_human]}",
                                                 "NewGoogleRecaptcha.minimum_score=#{NewGoogleRecaptcha.minimum_score}",
                                                 "@ngr_is_human=#{@ngr_is_human}",
                                                 "" ] if contact_form_controller_debug_verbose
        end
        @ngr_used = true
        @spam_status_unknown = false
      rescue => e
        Rails.logger.error("Unable to connect to google: #{e}, skipping check")
        @ngr_is_human = nil
        @ngr_humanity_details = nil
        @ngr_used = false
      end
    end

  end

end
