# frozen_string_literal: true

require './lib/irus_logger'
require_relative './logging_helper'

module Deepblue::ReportHelper


  def self.expand_path_partials( path )
    return path unless path.present?
    now = Time.now
    path = path.gsub( /\%date\%/, "#{now.strftime('%Y%m%d')}" )
    path = path.gsub( /\%time\%/, "#{now.strftime('%H%M%S')}" )
    path = path.gsub( /\%timestamp\%/, "#{now.strftime('%Y%m%d%H%M%S')}" )
    path = path.gsub( /\%hostname\%/, "#{Rails.configuration.hostname}" )
    return path
  end

end
