require 'spec_helper'

describe IrusAnalytics::IrusAnalyticsService do 
  let (:irus_analytics_service) { IrusAnalytics::IrusAnalyticsService.new("") }
  let (:test_params) { { date_stamp: "2010-10-17T03:04:42Z",
                         client_ip_address: "127.0.0.1",
                         user_agent: "Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405",
                         item_oai_identifier: "hull:123",
                         file_url: "https://hydra.hull.ac.uk/assets/hull:123/content",
                         http_referer: "https://www.google.co.uk/search?q=hydra+hull%3A123&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a&channel=sb&gfe_rd=cr",
                         source_repository: "hydra.hull.ac.uk"  } }

  describe ".send_analytics" do

    before (:each) do
       # Create a double for the transport object that will return 200 OK status
       transport = double("transport", :get => "", :code => "200")
       allow(irus_analytics_service).to receive(:openurl_link_resolver) .and_return(transport)
    end

    it "will throw an exception if the irus_server_address object variable is not set" do
      expect { irus_analytics_service.send_analytics(test_params) }.to raise_error
    end

    it "enables the required parameters to be set within a hash" do
       irus_analytics_service.irus_server_address = "irus_address"
       irus_analytics_service.send_analytics(test_params)
    end

    it "will throw an exception if any of the mandatory IRUS data is missing" do
      irus_analytics_service.irus_server_address = "irus_address"
      expect { irus_analytics_service.send_analytics({}) }.to raise_error(/Missing the following required params/)
    end

    it "will allow for a nil http referer" do
      irus_analytics_service.irus_server_address = "irus_address"
      test_params[:http_referer] = nil
      irus_analytics_service.send_analytics(test_params)
    end

  end
end
