require "spec_helper"

describe IrusAnalytics::Configuration do

  describe "expected values in testing" do
    it { expect(::IrusAnalytics::Configuration.enabled).to eq true }
    it { expect(::IrusAnalytics::Configuration.enable_send_investigations).to eq true }
    it { expect(::IrusAnalytics::Configuration.enable_send_logger).to eq true }
    it { expect(::IrusAnalytics::Configuration.enable_send_requests).to eq true }
    it { expect(::IrusAnalytics::Configuration.irus_server_address).to eq "https://irus.jisc.ac.uk/counter/test/" }
    it { expect(::IrusAnalytics::Configuration.robots_file).to eq "irus_analytics_counter_robot_list.txt" }
    it { expect(::IrusAnalytics::Configuration.source_repository).to eq "test.deepblue.lib.umich.edu/data" }
    it { expect(::IrusAnalytics::Configuration.verbose_debug).to eq false }

  end

end
