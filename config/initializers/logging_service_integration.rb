
suppress_active_support_logging = false

if suppress_active_support_logging
  #
  # Clean out some irritating logging behavior
  #
  STDOUT.puts "\nList of ActiveSupport::LogSubscriber.subscribers:"
  ActiveSupport::LogSubscriber.subscribers.each do |s|
    STDOUT.puts "-- #{s.to_s} -- #{s.patterns}"
  end
  # STDOUT.puts "#{ActiveSupport::LogSubscriber.subscribers}"
  STDOUT.puts "\nNow remove specified listeners from list of ActiveSupport::Notifications..."
  notifier = ActiveSupport::Notifications.notifier
  active_fedora = [ "logger.active_fedora" ]
  action_cable = [ "transmit_subscription_confirmation.action_cable",
                   "transmit_subscription_rejection.action_cable" ]
  action_view = [ "logger.active_fedora",
                  "render_collection.action_view",
                  "render_partial.action_view",
                  "render_template.action_view" ]
  active_record =   [ "sql.active_record" ]
  unsubscribe_these = []
  unsubscribe_these = unsubscribe_these + active_fedora
  unsubscribe_these = unsubscribe_these + action_cable
  unsubscribe_these = unsubscribe_these + action_view
  unsubscribe_these = unsubscribe_these + active_record
  unsubscribe_these.each do |unsubscribe_id|
    puts "ActiveSupport::Notifications.notifier unsubscribing #{unsubscribe_id}"
    subscribers = notifier.listeners_for( unsubscribe_id )
    count = 0
    subscribers.each { |subscriber| ActiveSupport::Notifications.unsubscribe( subscriber ); count += 1 }
    puts "ActiveSupport::Notifications.notifier unsubscribed #{count} for #{unsubscribe_id}" if count > 0
  end
  STDOUT.puts
  STDOUT.flush
end