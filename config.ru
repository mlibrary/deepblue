# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

APP_ROOT = Rails.configuration.relative_url_root || "/"

map APP_ROOT do
  run Rails.application
end

# Auto-redirect root URL hits to the app as a development convenience
if "/" != APP_ROOT
  map "/" do
    redirect_app = lambda do |env|
      req = Rack::Request.new(env)
      res = Rack::Response.new
      if /^\/*$/.match?(req.path)
        res.redirect(APP_ROOT)
      else
        res.status = 404
        res.write "The requested URL #{req.fullpath} was not found."
      end
      res.finish
    end
    run redirect_app
  end
end
