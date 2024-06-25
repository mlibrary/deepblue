# frozen_string_literal: true
# Reviewed: hyrax4

# Log content update to activity streams
class ContentUpdateEventJob < ContentEventJob
  def action
    url = ::Deepblue::EmailHelper.cc_url( curation_concern: repo_object, only_path: true )
    title = ::Deepblue::EmailHelper.cc_title( curation_concern: repo_object )
    "User #{link_to_profile depositor} has updated #{link_to repo_object.title.first, url}"
  end
end
