# frozen_string_literal: true

class AnonymousLink < ActiveRecord::Base

  after_initialize :set_defaults

  def create_for_path(path)
    self.class.create(itemId: itemId, path: path)
  end

  def expired?
    false
  end

  def to_param
    downloadKey
  end

  private

  def set_defaults
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "user_id=#{user_id}",
    #                                        "" ] if ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
    return unless new_record?
    self.downloadKey ||= (Digest::SHA2.new << rand(1_000_000_000).to_s).to_s
  end

end
