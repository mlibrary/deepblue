# frozen_string_literal: true

module EventLoggerJobBehavior
  include Rails.application.routes.url_helpers
  include ActionView::Helpers
  include HyraxHelper

  mattr_reader :depositor, :event

  # override to provide your specific action for the event you are logging
  # @abstract
  def action
    raise( NotImplementedError, I18n.t( "events.actions.event_logger_action_error" ) )
  end

  # create an event with an action and a timestamp for the user
  def event
    @event ||= Hyrax::Event.create( action, Time.current.to_i )
  end

  # Log the event to the object's stream
  def log_event( repo_object )
    repo_object.log_event( event ) if repo_object.respond_to? :log_event
  end

  # log the event to the users profile stream
  def log_user_profile_event
    depositor.log_profile_event( event ) if depositor.respond_to? :log_profile_event
  end

  # log the event to the users event stream
  def log_user_event
    depositor.log_event( event ) if depositor.respond_to? :log_event
  end

end
