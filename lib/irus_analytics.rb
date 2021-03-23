require "irus_analytics/version"
require "irus_analytics/controller/analytics_behaviour"
require "irus_analytics/irus_analytics_service"
require "irus_analytics/tracker_context_object_builder"
require "irus_analytics/user_agent_filter"
require "irus_analytics/irus_client"
require "irus_analytics/rail_tie" if defined?(Rails)
require "resque/server"


module IrusAnalytics
  class << self
    attr_writer :configuration 
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yeild(configuration)
  end

  def self.root
    @root ||= File.expand_path(File.dirname(File.dirname(__FILE__)))
  end

  def self.config
    File.join root, "config" 
  end

  class Configuration
    attr_accessor :source_repository, :irus_server_address

    def initialize
      @source_repository = "locahost:3000"
      @irus_server_address = "localhost:3000/irus"
    end
  end

end

