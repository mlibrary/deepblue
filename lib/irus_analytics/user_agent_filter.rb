require 'irus_analytics'
require 'singleton'

module IrusAnalytics
  class UserAgentFilter
    include Singleton

    # Singleton module defines us a instance class method and makes this private...
    def initialize
      set_robot_agents
    end

    def filter_user_agent?(user_agent)
      @robot_agents.each do |robot_regexp|
        return true unless user_agent.match(robot_regexp).nil? 
      end
      return false
    end

    def set_robot_agents
      @robot_agents = get_robots_from_config
    end
  
    private

    def get_robots_from_config
      begin 
        agent_list = File.open("#{IrusAnalytics.config}/counter_robot_list.txt", "r") { |config| config.readlines.collect{|line| line.chomp }}
      rescue Exception => ex
          # Deal with configuration read error
          agent_list = []
      end
    end

  end
end