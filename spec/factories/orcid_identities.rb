# frozen_string_literal: true
# hyrax-orcid

FactoryBot.define do
  factory :orcid_identity do
    name { "John Smith" }
    # Create a random orcid_id, 4 groups of 4, 4 digit numbers, hyphen seperated, i.e. "6245-1498-7128-1812"
    # NOTE: Sometimes random_number(10**16) only returns a 15 digit int, so rjust pads to ensure its always 16 chars
    orcid_id { SecureRandom.random_number(10**16).to_s.rjust(16, "0").scan(/.{1,4}/).join("-") }
    access_token { SecureRandom.uuid }
    token_type { "bearer" }
    refresh_token { SecureRandom.uuid }
    expires_in { 5.years.from_now.to_i.to_s }
    scope { "/read-limited /activities/update" }
    profile_sync_preference { {} }
  end
end
