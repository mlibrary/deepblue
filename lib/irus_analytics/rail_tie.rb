require "rails"

# Used to push rake tasks up to app using gem
module IrusAnalytics
  class Railtie < Rails::Railtie
    railtie_name :irus_analytics

    rake_tasks do
      load "tasks/resque.rake"
    end

  end
end