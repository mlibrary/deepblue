# frozen_string_literal: true

require "uri"
require "net/http"
require 'json'

module McommunityHelper

  def self.make_request ( unique_id )
    token = get_token

    url = URI("#{Settings.mcommunity.url}MCommunity/People/" + unique_id)

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["Accept"] = "application/json"
    request["Authorization"] = "Bearer " + token
    request["x-ibm-client-id"] = Settings.mcommunity.client_id

    response = https.request(request)

    value = response.read_body
    return JSON.parse(value)
  end

  def self.get_token
    url = URI("#{Settings.mcommunity.url}oauth2/token?grant_type=client_credentials&scope=mcommunity")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["Accept"] = "application/json"
    request["Authorization"] = "Basic " + Settings.mcommunity.authorization
    request["x-ibm-client-id"] = Settings.mcommunity.client_id

    response = https.request(request)
    value = response.read_body
    obj = JSON.parse(value)
    return obj['access_token']
  end

  def self.get_orchid( email )
    unique_id = email.split('@')[0].strip
    obj = make_request ( unique_id )
    return obj['person']['scholarId']
  end

  def self.get_name( email )
    unique_id = email.split('@')[0].strip
    obj = make_request ( unique_id )
    return obj['person']['displayName']
  end 

  def self.get_affiliation( email )
    unique_id = email.split('@')[0].strip
    obj = make_request ( unique_id )
    return "" if obj['person']['affiliation'].nil? || obj['person']['affiliation'].empty?
    return obj['person']['affiliation'].join('; ')
  end 



end
