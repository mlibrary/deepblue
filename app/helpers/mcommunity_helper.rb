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
    request["Cookie"] = Settings.mcommunity.cookie

    response = https.request(request)

    value = response.read_body
    return JSON.parse(value)
  end

	def self.get_token
    url = URI("#{Settings.mcommunity.url}inst/oauth2/token?grant_type=client_credentials&scope=mcommunity")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["Accept"] = "application/json"
    request["Authorization"] = "Basic " + Settings.mcommunity.authorization
    request["x-ibm-client-id"] = Settings.mcommunity.client_id
    request["Cookie"] = Settings.mcommunity.cookie

    response = https.request(request)
    value = response.read_body
    obj = JSON.parse(value)
    return obj['access_token']
	end

  def self.get_orchid( uid )
    unique_id = uid.split('@')[0].strip
    obj = make_request ( unique_id )
    return obj['person']['scholarId']
  end

  def self.get_name( uid )
    unique_id = uid.split('@')[0].strip
    obj = make_request ( unique_id )
    return obj['person']['displayName']
  end 

  def self.get_affiliation( uid )
    unique_id = uid.split('@')[0].strip
    obj = make_request ( unique_id )
    return "" if obj['person']['affiliation'].nil? || obj['person']['affiliation'].empty?
    return obj['person']['affiliation'].join('; ')
  end 



end
