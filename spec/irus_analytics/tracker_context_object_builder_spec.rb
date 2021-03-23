require 'spec_helper'

describe IrusAnalytics::TrackerContextObjectBuilder do
  describe ".initialize" do
    it "will initialize an empty OpenURL::ContextObject instance" do
      expect(IrusAnalytics::TrackerContextObjectBuilder.new.context_object).to be_an_instance_of OpenURL::ContextObject
    end
  end

  context "set methods" do
    let(:builder) { IrusAnalytics::TrackerContextObjectBuilder.new }

     describe "OpenURL version" do
       it "will be defaulted to required version for IRUS" do
        expect(builder.context_object.kev).to include("url_ver=Z39.88-2004")        
       end
     end

    describe "set_event_datestamp" do
      it "will set event datestamp as per IRUS specification" do
        date_time = "2010-10-17T03:04:42Z"
        builder.set_event_datestamp(date_time)
        expect(builder.context_object.kev).to include("url_tim=2010-10-17T03%3A04%3A42Z")        # Html_encoded version of the string
      end
    end

    describe "set_client_ip_address" do
       it "will set client ip address as per IRUS specification" do
         ip_address = "127.0.0.1"
         builder.set_client_ip_address(ip_address)
         expect(builder.context_object.kev).to include("req_id=urn%3Aip%3A127.0.0.1") 
       end
    end

    describe "set_user_agent" do
      it "will set the request UserAgent as per IRUS specification" do
        agent = "Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405"
        builder.set_user_agent(agent)
        expect(builder.context_object.kev).to include("req_dat=Mozilla%2F5.0+%28iPad%3B+U%3B+CPU+OS+3_2_1+like+Mac+OS+X%3B+en-us%29+AppleWebKit%2F531.21.10+%28KHTML%2C+like+Gecko%29+Mobile%2F7B405")
      end
    end

    describe "set_oai_identifier" do
      it "will set the item oai identifier as per IRUS specification" do
        identifier = "oai:hull.ac.uk:hull:123"
        builder.set_oai_identifier(identifier)
        expect(builder.context_object.kev).to include("rft.artnum=oai%3Ahull.ac.uk%3Ahull%3A123")
      end
    end

    describe "set_file_url" do
      it "will set FileURL as per IRUS specification" do
        url = "https://hydra.hull.ac.uk/assets/hull:123/content"
        builder.set_file_url(url)
        expect(builder.context_object.kev).to include("svc_dat=https%3A%2F%2Fhydra.hull.ac.uk%2Fassets%2Fhull%3A123%2Fcontent")
      end
    end

    describe "set_http_referer" do
      it "will set the HTTP referer as per IRUS specification" do
        referer = "http://www.google.co.uk/url?sa=t&rct=j&q=http%20referer&source=web&cd=4&sqi=2&ved=0CEoQFjAD&url=http%3A%2F%2Fwww.whatismyreferer.com%2F&ei=zIBCU6fbEoOqhQf67YCwBg&usg=AFQjCNFt-KMqneTZfEb6OxjPZlD4ogiJcQ&sig2=wZJYkoWgNScNjgxRbRs29w&bvm=bv.64125504,d.ZWU"
        builder.set_http_referer(referer)
        expect(builder.context_object.kev).to include("rfr_dat=http%3A%2F%2Fwww.google.co.uk%2Furl%3Fsa%3Dt%26rct%3Dj%26q%3Dhttp%2520referer%26source%3Dweb%26cd%3D4%26sqi%3D2%26ved%3D0CEoQFjAD%26url%3Dhttp%253A%252F%252Fwww.whatismyreferer.com%252F%26ei%3DzIBCU6fbEoOqhQf67YCwBg%26usg%3DAFQjCNFt-KMqneTZfEb6OxjPZlD4ogiJcQ%26sig2%3DwZJYkoWgNScNjgxRbRs29w%26bvm%3Dbv.64125504%2Cd.ZWU")
      end
    end

    describe "set_source_repository" do
      it "will set the Source repository as per IRUS specification" do
        src_repo = "hydra.hull.ac.uk"
        builder.set_source_repository(src_repo)
        expect(builder.context_object.kev).to include("rfr_id=hydra.hull.ac.uk")
      end
    end


  end

end