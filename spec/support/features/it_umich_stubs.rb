# frozen_string_literal: true

RSpec.configure do |config|

  config.before(it_umich: true) do

    stub_request(:post, "https://apigw.it.umich.edu/um/inst/oauth2/token?grant_type=client_credentials&scope=mcommunity").
      with(
        headers: {
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization'=>'Basic BEARER',
          'Cookie'=>'COOKIE',
          'Host'=>'apigw.it.umich.edu',
          'User-Agent'=>'Ruby',
          'X-Ibm-Client-Id'=>'CLIENT_ID'
        }).to_return( status: 200, body: "", headers: {} )

  end

end
