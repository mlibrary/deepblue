require 'openurl'

module OpenURL

  # monkey / fix the lack of https
  # see:
  class TransportHttps < OpenURL::Transport
    def initialize(target_base_url, contextobject=nil, http_arguments={})
      super
      @client.use_ssl = true
    end
  end

end
