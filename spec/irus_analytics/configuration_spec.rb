require "spec_helper"

describe IrusAnalytics::Configuration do

  describe "irus analytics config file exists" do
    it { expect(File.exist? Rails.root.join('config', 'irus_analytics_config.yml')).to eq true }
  end

  describe "expected values in testing" do
    it { expect(::IrusAnalytics::Configuration.enabled).to eq true }
    it { expect(::IrusAnalytics::Configuration.enable_send_logger).to eq true }
    it { expect(::IrusAnalytics::Configuration.irus_server_address).to eq "https://irus.jisc.ac.uk/counter/test/" }
    it { expect(::IrusAnalytics::Configuration.robots_file).to eq "irus_analytics_counter_robot_list.txt" }
    it { expect(::IrusAnalytics::Configuration.source_repository).to eq "test.deepblue.lib.umich.edu/data" }
    it { expect(::IrusAnalytics::Configuration.verbose_debug).to eq true }
  end

  describe "robot list exists" do
    it { expect(File.exist? Rails.root.join('config', 'irus_analytics_counter_robot_list.txt')).to eq true }
  end

end