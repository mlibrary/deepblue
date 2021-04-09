require "spec_helper"

require 'irus_analytics/elements'

describe IrusAnalytics do

  describe "expected values" do
    it { expect(IrusAnalytics::OPENURL_VERSION).to eq 'Z39.88-2004' }
    it { expect(IrusAnalytics::INVESTIGATION).to eq 'Investigation' }
    it { expect(IrusAnalytics::REQUEST).to eq 'Request' }
    expected_handles = { event_datestamp:     "url_tim",
                         file_url:            "svc_dat",
                         http_referer:        "rfr_dat",
                         ip_address:          "req_id",
                         item_oai_identifier: "rft.artnum",
                         openurl_version:     "url_ver",
                         source_repository:   "rfr_id",
                         usage_event_type:    "rft_dat",
                         user_agent:          "req_dat" }
    it { expect(IrusAnalytics.handles).to eq expected_handles }
    expected_usage_event_types = { investigation: IrusAnalytics::INVESTIGATION, request: IrusAnalytics::REQUEST }
    it { expect(IrusAnalytics.usage_event_types).to eq expected_usage_event_types }

  end

end
