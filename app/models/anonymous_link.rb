# frozen_string_literal: true

class AnonymousLink < ActiveRecord::Base
  include LinkBehavior

  alias_attribute :downloadKey, :download_key
  alias_attribute :itemId, :item_id

  after_initialize :set_defaults

  def self.find_or_create( id:,
                           path:,
                           debug_verbose: ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "path=#{path}",
                                           "" ] if debug_verbose
    anon_links = AnonymousLink.where( item_id: id, path: path )
    if anon_links.present?
      rv_mode = 'found'
      rv = anon_links.first
    else
      rv_mode =' created'
      rv = AnonymousLink.create( item_id: id, path: path )
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "rv_mode=#{rv_mode}",
                                           "id=#{id}",
                                           "path=#{path}",
                                           "rv=#{rv}",
                                           "" ] if debug_verbose
    return rv
  end

  def create_for_path(path)
    self.class.create(item_id: item_id, path: path)
  end

  def expired?
    false
  end

  def to_param
    download_key
  end

  private

    def cannot_be_destroyed
      errors[:base] << "Anonymous Link has already been destroyed" if destroyed? # TODO: convert to I18N
    end

    def set_defaults
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "user_id=#{user_id}",
      #                                        "" ] if ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      return unless new_record?
      self.download_key ||= generate_download_key
    end

end
