require 'spec_helper'

require 'irus_analytics/elements'

class TestClass
  include IrusAnalytics::Controller::AnalyticsBehaviour
  attr_accessor :request, :item_identifier
end

describe IrusAnalytics::Controller::AnalyticsBehaviour do

  describe "irus analytics is enabled" do
    it { expect(::IrusAnalytics::Configuration.enabled).to eq true }
  end

  describe ".send_irus_analytics" do
    before(:each) do
       @test_class = TestClass.new
       @test_class.request  = double("request", :remote_ip => "127.0.0.1", :user_agent => "Test user agent",  url: "http://localhost:3000/test", referer: "http://localhost:3000", headers: { "HTTP_RANGE" => nil })
       @test_class.item_identifier = "test:123"
    end

    it "will call the send_irus_analytics method with the correct params..." do
       # We set the datetime stamp to ensure sync
       date_time = "2014-06-09T16:56:48Z"
       allow(@test_class).to receive(:datetime_stamp) .and_return(date_time)
       allow(@test_class).to receive(:source_repository) .and_return("hydra.hull.ac.uk")
       allow(@test_class).to receive(:irus_server_address) .and_return("irus-server-address.org")
       params = { date_stamp: date_time,
                  client_ip_address: "127.0.0.1",
                  user_agent: "Test user agent",
                  item_oai_identifier: "test:123",
                  file_url: "http://localhost:3000/test",
                  http_referer: "http://localhost:3000",
                  source_repository: "hydra.hull.ac.uk"
       }
       allow(Resque).to receive(:enqueue) .and_return(nil)
       # Should NOT filter this request
       expect(@test_class).to receive(:filter_request?).and_return(false)
       expect(Resque).to receive(:enqueue).with(IrusAnalytics::IrusClient,
                                                "irus-server-address.org",
                                                params, IrusAnalytics::REQUEST )
       @test_class.send_irus_analytics
    end

    it "will not call the send_irus_analytics method when there is a filter user-agent.." do
       # Add a well known robot... 
       @test_class.request  = double("request", :remote_ip => "127.0.0.1", :user_agent => "Microsoft URL Control - 6.00.8862",  url: "http://localhost:3000/test", referer: "http://localhost:3000", headers: { "HTTP_RANGE" => nil })
       # We set the datetime stamp to ensure sync
       date_time = "2014-06-09T16:56:48Z"
       allow(@test_class).to receive(:datetime_stamp) .and_return(date_time)
       allow(@test_class).to receive(:source_repository) .and_return("hydra.hull.ac.uk")
       allow(@test_class).to receive(:irus_server_address) .and_return("irus-server-address.org")
       params = { date_stamp: date_time, client_ip_address: "127.0.0.1", user_agent: "Microsoft URL Control - 6.00.8862" ,item_oai_identifier: "test:123",
                  file_url: "http://localhost:3000/test", http_referer: "http://localhost:3000",  source_repository: "hydra.hull.ac.uk" }

       allow(Resque).to receive(:enqueue) .and_return(nil)
       # Should filter this request
       expect(Resque).to_not receive(:enqueue).with(IrusAnalytics::IrusClient, "irus-server-address.org", params )
       @test_class.send_irus_analytics
    end


    it "will not call the send_irus_analytics method when the request is expecting a chunk of data (HTTP_RANGE downloading data)." do
       # Add a well known robot... 
       @test_class.request  = double("request", :remote_ip => "127.0.0.1", :user_agent =>"Test user agent",  url: "http://localhost:3000/test", referer: "http://localhost:3000", headers: { "HTTP_RANGE" => "bytes=0-65535"})
       # We set the datetime stamp to ensure sync
       date_time = "2014-06-09T16:56:48Z"
       allow(@test_class).to receive(:datetime_stamp) .and_return(date_time)
       allow(@test_class).to receive(:source_repository) .and_return("hydra.hull.ac.uk")
       allow(@test_class).to receive(:irus_server_address) .and_return("irus-server-address.org")
       params = { date_stamp: date_time, client_ip_address: "127.0.0.1", user_agent: "Microsoft URL Control - 6.00.8862" ,item_oai_identifier: "test:123",
                  file_url: "http://localhost:3000/test", http_referer: "http://localhost:3000",  source_repository: "hydra.hull.ac.uk" }

       allow(Resque).to receive(:enqueue) .and_return(nil)
       # Should filter this request
       expect(Resque).to_not receive(:enqueue).with(IrusAnalytics::IrusClient, "irus-server-address.org", params )
       @test_class.send_irus_analytics
    end


  end  
end
