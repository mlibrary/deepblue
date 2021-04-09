require 'spec_helper'

require 'irus_analytics/elements'

describe IrusAnalytics::IrusAnalyticsService do 
  let (:irus_analytics_service) { IrusAnalytics::IrusAnalyticsService.new("") }

  let(:client_ip_address)   { "127.0.0.1" }
  let(:date_stamp)          { "2010-10-17T03:04:42Z" }
  let(:file_url)            { "https://hydra.hull.ac.uk/assets/hull:123/content" }
  let(:http_referer)        { "https://www.google.co.uk/search?q=hydra+hull%3A123&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a&channel=sb&gfe_rd=cr" }
  let(:item_oai_identifier) { "hull:123" }
  let(:source_repository)   { "hydra.hull.ac.uk" }
  let(:user_agent)          { "Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405" }

  let (:test_params) { { client_ip_address:   client_ip_address,
                         date_stamp:          date_stamp,
                         file_url:            file_url,
                         http_referer:        http_referer,
                         item_oai_identifier: item_oai_identifier,
                         source_repository:   source_repository,
                         user_agent:          user_agent } }

  let(:code) { "200" }

  describe "irus analytics is enabled" do
    it { expect(::IrusAnalytics::Configuration.enabled).to eq true }
  end

  describe ".send_analytics" do

    before (:each) do
       # Create a double for the transport object that will return 200 OK status
       transport = double("transport", :get => "", :code => code)
       allow(irus_analytics_service).to receive(:openurl_link_resolver).and_return(transport)
    end

    it "will throw an exception if the irus_server_address object variable is not set" do
      expect { irus_analytics_service.send_analytics(test_params) }.to raise_error
    end

    it "enables the required parameters to be set within a hash" do
       irus_analytics_service.irus_server_address = "irus_address"
       irus_analytics_service.send_analytics(test_params)
       expect(irus_analytics_service.irus_server_address).to eq "irus_address"
       # expect(irus_analytics_service.transport_response_code).to eq code
       context_object = irus_analytics_service.tracker_context_object_builder.context_object
       kev = context_object.kev
       expect(kev).to include("#{IrusAnalytics.handles[:event_datestamp]}=#{CGI.escape date_stamp}")
       expect(kev).to include("#{IrusAnalytics.handles[:file_url]}=#{CGI.escape file_url}")
       expect(kev).to include("#{IrusAnalytics.handles[:http_referer]}=#{CGI.escape http_referer}")
       expect(kev).to include("#{IrusAnalytics.handles[:item_oai_identifier]}=#{CGI.escape item_oai_identifier}")
       expect(kev).to include("#{IrusAnalytics.handles[:source_repository]}=#{CGI.escape source_repository}")
       expect(kev).to include("#{IrusAnalytics.handles[:usage_event_type]}=#{IrusAnalytics::REQUEST}")
       expect(kev).to include("#{IrusAnalytics.handles[:user_agent]}=#{CGI.escape user_agent}")
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

  describe ".send_analytics_request" do

    before (:each) do
      # Create a double for the transport object that will return 200 OK status
      transport = double("transport", :get => "", :code => code)
      allow(irus_analytics_service).to receive(:openurl_link_resolver).and_return(transport)
    end

    it "enables the required parameters to be set within a hash" do
      irus_analytics_service.irus_server_address = "irus_address"
      irus_analytics_service.send_analytics_request(test_params)
      expect(irus_analytics_service.irus_server_address).to eq "irus_address"
      # expect(irus_analytics_service.transport_response_code).to eq code
      context_object = irus_analytics_service.tracker_context_object_builder.context_object
      kev = context_object.kev
      expect(kev).to include("#{IrusAnalytics.handles[:event_datestamp]}=#{CGI.escape date_stamp}")
      expect(kev).to include("#{IrusAnalytics.handles[:file_url]}=#{CGI.escape file_url}")
      expect(kev).to include("#{IrusAnalytics.handles[:http_referer]}=#{CGI.escape http_referer}")
      expect(kev).to include("#{IrusAnalytics.handles[:item_oai_identifier]}=#{CGI.escape item_oai_identifier}")
      expect(kev).to include("#{IrusAnalytics.handles[:source_repository]}=#{CGI.escape source_repository}")
      expect(kev).to include("#{IrusAnalytics.handles[:usage_event_type]}=#{IrusAnalytics::REQUEST}")
      expect(kev).to include("#{IrusAnalytics.handles[:user_agent]}=#{CGI.escape user_agent}")
    end

  end

  describe ".send_analytics_investigation" do

    before (:each) do
      # Create a double for the transport object that will return 200 OK status
      transport = double("transport", :get => "", :code => code)
      allow(irus_analytics_service).to receive(:openurl_link_resolver).and_return(transport)
    end

    it "enables the required parameters to be set within a hash" do
      irus_analytics_service.irus_server_address = "irus_address"
      irus_analytics_service.send_analytics_investigation(test_params)
      expect(irus_analytics_service.irus_server_address).to eq "irus_address"
      # expect(irus_analytics_service.transport_response_code).to eq code
      context_object = irus_analytics_service.tracker_context_object_builder.context_object
      kev = context_object.kev
      expect(kev).to include("#{IrusAnalytics.handles[:event_datestamp]}=#{CGI.escape date_stamp}")
      expect(kev).to include("#{IrusAnalytics.handles[:file_url]}=#{CGI.escape file_url}")
      expect(kev).to include("#{IrusAnalytics.handles[:http_referer]}=#{CGI.escape http_referer}")
      expect(kev).to include("#{IrusAnalytics.handles[:item_oai_identifier]}=#{CGI.escape item_oai_identifier}")
      expect(kev).to include("#{IrusAnalytics.handles[:source_repository]}=#{CGI.escape source_repository}")
      expect(kev).to include("#{IrusAnalytics.handles[:usage_event_type]}=#{IrusAnalytics::INVESTIGATION}")
      expect(kev).to include("#{IrusAnalytics.handles[:user_agent]}=#{CGI.escape user_agent}")
    end

  end

end
