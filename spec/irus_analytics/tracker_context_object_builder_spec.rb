require 'spec_helper'

require 'irus_analytics/elements'

describe IrusAnalytics::TrackerContextObjectBuilder do

  describe ".initialize" do
    it "will initialize an empty OpenURL::ContextObject instance" do
      expect(IrusAnalytics::TrackerContextObjectBuilder.new.context_object).to be_an_instance_of OpenURL::ContextObject
    end
  end

  context "get methods" do
    let(:builder) { IrusAnalytics::TrackerContextObjectBuilder.new }

    it "has a context_object" do
      expect(builder.context_object).to_not eq nil
    end
  end

  context "set methods" do
    let(:builder) { IrusAnalytics::TrackerContextObjectBuilder.new }

    describe "OpenURL version" do
      it "will be defaulted to required version for IRUS" do
        expect(builder.context_object.kev).to include("url_ver=Z39.88-2004")
      end
    end

    describe "set_client_ip_address" do
      it "will set client ip address as per IRUS specification" do
        ip_address = "127.0.0.1"
        builder.set_client_ip_address(ip_address)
        # expect(builder.context_object.kev).to include("req_id=urn%3Aip%3A127.0.0.1")
        expect(builder.context_object.kev).to include("#{IrusAnalytics.handles[:ip_address]}=urn%3Aip%3A127.0.0.1")
      end
    end

    describe "set_event_datestamp" do
      it "will set event datestamp as per IRUS specification" do
        date_time = "2010-10-17T03:04:42Z"
        builder.set_event_datestamp(date_time)
        expected_value = CGI.escape(date_time)
        expect(builder.context_object.kev).to include("#{IrusAnalytics.handles[:event_datestamp]}=#{expected_value}")
      end
    end

    describe "set_file_url" do
      it "will set FileURL as per IRUS specification" do
        url = "https://hydra.hull.ac.uk/assets/hull:123/content"
        builder.set_file_url(url)
        expected_value = CGI.escape(url)
        expect(builder.context_object.kev).to include("#{IrusAnalytics.handles[:file_url]}=#{expected_value}")
      end
    end

    describe "set_http_referer" do
      it "will set the HTTP referer as per IRUS specification" do
        referer = "http://www.google.co.uk/url?sa=t&rct=j&q=http%20referer&source=web&cd=4&sqi=2&ved=0CEoQFjAD&url=http%3A%2F%2Fwww.whatismyreferer.com%2F&ei=zIBCU6fbEoOqhQf67YCwBg&usg=AFQjCNFt-KMqneTZfEb6OxjPZlD4ogiJcQ&sig2=wZJYkoWgNScNjgxRbRs29w&bvm=bv.64125504,d.ZWU"
        builder.set_http_referer(referer)
        expected_value = CGI.escape(referer)
        expect(builder.context_object.kev).to include("#{IrusAnalytics.handles[:http_referer]}=#{expected_value}")
      end
    end

    describe "set_item_oai_identifier" do
      it "will set the item oai identifier as per IRUS specification" do
        identifier = "oai:hull.ac.uk:hull:123"
        builder.set_item_oai_identifier(identifier)
        expected_value = CGI.escape(identifier)
        expect(builder.context_object.kev).to include("#{IrusAnalytics.handles[:item_oai_identifier]}=#{expected_value}")
      end
    end

    describe "set_source_repository" do
      it "will set the Source repository as per IRUS specification" do
        src_repo = "hydra.hull.ac.uk"
        builder.set_source_repository(src_repo)
        expect(builder.context_object.kev).to include("#{IrusAnalytics.handles[:source_repository]}=#{src_repo}")
      end
    end

    describe "set_usage_event_type" do
      it "will set the usage event type to Request" do
        usage_event_type = IrusAnalytics::REQUEST
        builder.set_usage_event_type(usage_event_type)
        expect(builder.context_object.kev).to include("#{IrusAnalytics.handles[:usage_event_type]}=#{usage_event_type}")
      end
      it "will set the usage event type to Investigation" do
        usage_event_type = IrusAnalytics::INVESTIGATION
        builder.set_usage_event_type(usage_event_type)
        expect(builder.context_object.kev).to include("#{IrusAnalytics.handles[:usage_event_type]}=#{usage_event_type}")
      end
    end

    describe "set_user_agent" do
      it "will set the request UserAgent as per IRUS specification" do
        agent = "Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405"
        builder.set_user_agent(agent)
        expected_value = CGI.escape(agent)
        expect(builder.context_object.kev).to include("#{IrusAnalytics.handles[:user_agent]}=#{expected_value}")
      end
    end

  end

end
