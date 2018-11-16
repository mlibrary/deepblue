# frozen_string_literal: true

# see: https://github.com/rack/rack/issues/1075#issuecomment-256939491
#
# Then add the following in config/application.rb
# config.middleware.insert_before Rack::Runtime, RackMultipartBufSizeSetter

class RackMultipartBufSizeSetter

  def initialize(app)
    @app = app
  end

  def call(env)
    # env.merge!( Rack::RACK_MULTIPART_BUFFER_SIZE => 100 * 1024 * 1024 )
    env.merge!( Rack::RACK_MULTIPART_BUFFER_SIZE => 1024 * 1024 )
    @app.call(env)
  end

end
