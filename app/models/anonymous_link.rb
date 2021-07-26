# frozen_string_literal: true

class AnonymousLink < ActiveRecord::Base

  def self.find_or_create( id:,
                           path:,
                           debug_verbose: ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "path=#{path}",
                                           "" ] if debug_verbose
    anon_links = AnonymousLink.where( itemId: id, path: path )
    if anon_links.present?
      rv_mode = 'found'
      rv = anon_links.first
    else
      rv_mode =' created'
      rv = AnonymousLink.create( itemId: id, path: path )
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

  after_initialize :set_defaults

  def create_for_path(path)
    self.class.create(itemId: itemId, path: path)
  end

  def expired?
    false
  end

  def path_eq?( other_path )
    path_strip_locale( path ) == path_strip_locale( other_path )
  end

  def to_param
    downloadKey
  end

  private

    def path_strip_locale( the_path )
      return the_path if the_path.blank?
      if the_path =~ /^(.+)\?.+/
        return Regexp.last_match[1]
      end
      return the_path
    end

    def cannot_be_destroyed
      errors[:base] << "Anonymous Link has already been destroyed" if destroyed? # TODO: convert to I18N
    end

    def set_defaults
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "user_id=#{user_id}",
      #                                        "" ] if ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      return unless new_record?
      self.downloadKey ||= (Digest::SHA2.new << rand(1_000_000_000).to_s).to_s
    end

end
