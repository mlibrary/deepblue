# frozen_string_literal: true

# Log work depositor change to activity streams
#
# @attr [Boolean] reset (false) should the access controls be reset. This means revoking edit access from the depositor
class ContentDepositorChangeEventJob < ContentEventJob

  mattr_accessor :content_depositor_change_event_job_debug_verbose, default: false

  include Rails.application.routes.url_helpers
  include ActionDispatch::Routing::PolymorphicRoutes

  attr_accessor :reset

  # @param [ActiveFedora::Base] work the work to be transfered
  # @param [User] user the user the work is being transfered to.
  # @param [TrueClass,FalseClass] reset (false) if true, reset the access controls. This revokes edit access from the depositor
  def perform(work, user, reset = false)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "work=#{work}",
                                           "user=#{user}",
                                           "reset=#{reset}",
                                           "" ] if content_depositor_change_event_job_debug_verbose
    @reset = reset
    super(work, user)
  end

  def action
    I18n.t!( "events.actions.content_depositor_change",
            user_from: link_to_profile( work.proxy_depositor ),
            title: link_to_work( work.title.first ),
            user_to: link_to_profile( depositor ) )
  end

  def link_to_work(text)
    link_to text, polymorphic_path(work)
  end

  # Log the event to the work's stream
  def log_work_event(work)
    work.log_event(event)
  end
  alias log_file_set_event log_work_event

  def work
    @work ||= work_init
  end

  def work_init
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "repo_object=#{repo_object}",
                                           "depositor=#{depositor}",
                                           "reset=#{reset}",
                                           "" ] if content_depositor_change_event_job_debug_verbose
    Hyrax::ChangeContentDepositorService.call(repo_object, depositor, reset)
  end

  # overriding default to log the event to the depositor instead of their profile
  def log_user_event(depositor)
    # log the event to the proxy depositor's profile
    proxy_depositor.log_profile_event(event)
    depositor.log_event(event)
  end

  def proxy_depositor
    @proxy_depositor ||= ::User.find_by_user_key(work.proxy_depositor)
  end

end
