
if false
  #
  # Clean out some irritating logging behavior
  #
  STDOUT.puts "\nList of ActiveSupport::LogSubscriber.subscribers:"
  ActiveSupport::LogSubscriber.subscribers.each do |s|
    STDOUT.puts "-- #{s.to_s} -- #{s.patterns}"
  end
  # STDOUT.puts "#{ActiveSupport::LogSubscriber.subscribers}"
  STDOUT.puts "\nNow remove sql.active_record listeners from ist of ActiveSupport::LogSubscriber.subscribers..."
  notifier = ActiveSupport::Notifications.notifier
  #STDOUT.puts "\n#{notifier.subscribers}\n"
  subscribers = notifier.listeners_for("sql.active_record")
  subscribers.each {|s| ActiveSupport::Notifications.unsubscribe s }
  # STDOUT.puts "\nList of ActiveSupport::LogSubscriber.subscribers:"
  # ActiveSupport::LogSubscriber.subscribers.each do |s|
  #   STDOUT.puts "-- #{s.to_s} -- #{s.patterns}"
  # end
  STDOUT.puts
  STDOUT.flush
end