require 'spec_helper'

describe IrusAnalytics::UserAgentFilter do

  context "singleton" do
    describe ".instance" do
      it "should return the singleton instance of the RobotsFilter" do
        expect(IrusAnalytics::UserAgentFilter.instance).to be_instance_of IrusAnalytics::UserAgentFilter
      end
    end

    describe ".filter_user_agent" do
       it "will return true when a user agent should be filtered" do
         expect(IrusAnalytics::UserAgentFilter.instance.filter_user_agent?("appie")).to be true
       end

       it "will return false when a user agent is valid and should not be filtered" do
        expect(IrusAnalytics::UserAgentFilter.instance.filter_user_agent?("Firefox 3.0")).to be false
       end
    end
 
  end
end