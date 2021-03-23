require "openurl"

module IrusAnalytics
  class TrackerContextObjectBuilder
    attr_accessor :context_object
    def initialize
      @context_object = OpenURL::ContextObject.new
    end

    def set_event_datestamp(datetime)
      @context_object.admin.merge!("url_tim"=>{"label"=>"Usage event datestamp", "value"=>datetime})
    end
    
    def set_client_ip_address(ip_address)
      @context_object.admin.merge!("req_id"=>{"label"=>"Client IP address", "value"=>"urn:ip:#{ip_address}"})
    end

    def set_user_agent(user_agent)
      @context_object.admin.merge!("req_dat"=>{"label"=>"UserAgent", "value"=>user_agent})
    end

    def set_oai_identifier(identifier)
       @context_object.referent.set_metadata("artnum", identifier)
    end

    def set_file_url(url)
      @context_object.admin.merge!("svc_dat"=>{"label"=>"FileURL", "value"=>url})
    end

    def set_http_referer(referer)
      @context_object.admin.merge!("rfr_dat"=>{"label"=>"HTTP referer", "value"=>referer})
    end

    def set_source_repository(source_repository)
      @context_object.admin.merge!("rfr_id"=>{"label"=>"Source repository", "value"=>source_repository})
    end

  end
end