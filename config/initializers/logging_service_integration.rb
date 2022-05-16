
# suppress_active_support_logging = true
# suppress_active_support_logging_active_view_render = false
# suppress_active_support_logging_verbose = true
#
# if suppress_active_support_logging
#   #
#   # Clean out some irritating logging behavior
#   #
#   if suppress_active_support_logging_verbose
#     STDOUT.puts "\nList of ActiveSupport::LogSubscriber.subscribers:"
#     ActiveSupport::LogSubscriber.subscribers.each do |s|
#       STDOUT.puts "-- #{s.to_s} -- #{s.patterns.size} pattern(s)"
#       s.patterns.each_with_index do |p,i|
#         STDOUT.puts "---- #{i} - #{p}"
#       end
#     end
#     # STDOUT.puts "#{ActiveSupport::LogSubscriber.subscribers}"
#     STDOUT.puts "\nNow remove specified listeners from list of ActiveSupport::Notifications..."
#   end
#   notifier = ActiveSupport::Notifications.notifier
#   active_fedora = [ "logger.active_fedora",
#                     "ldp.active_fedora" ]
#   action_cable = [ "transmit_subscription_confirmation.action_cable",
#                    "transmit_subscription_rejection.action_cable" ]
#   action_view = [ "logger.active_fedora" ]
#   action_view_render = [ "render_collection.action_view",
#                          "render_partial.action_view",
#                          "render_template.action_view" ]
#   active_record =   [ "sql.active_record" ]
#   unsubscribe_these = []
#   unsubscribe_these = unsubscribe_these + active_fedora
#   unsubscribe_these = unsubscribe_these + action_cable
#   unsubscribe_these = unsubscribe_these + action_view
#   unsubscribe_these = unsubscribe_these + action_view_render if suppress_active_support_logging_active_view_render
#   unsubscribe_these = unsubscribe_these + active_record
#   unsubscribe_these.each do |unsubscribe_id|
#     STDOUT.puts "ActiveSupport::Notifications.notifier unsubscribing #{unsubscribe_id}" if suppress_active_support_logging_verbose
#     subscribers = notifier.listeners_for( unsubscribe_id )
#     count = 0
#     subscribers.each { |subscriber| ActiveSupport::Notifications.unsubscribe( subscriber ); count += 1 }
#     STDOUT.puts "ActiveSupport::Notifications.notifier unsubscribed #{count} for #{unsubscribe_id}" if count > 0 if suppress_active_support_logging_verbose
#   end
#   STDOUT.puts if suppress_active_support_logging_verbose
#   STDOUT.flush if suppress_active_support_logging_verbose
# end
