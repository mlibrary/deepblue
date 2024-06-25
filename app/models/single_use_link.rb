# frozen_string_literal: true
# Reviewed: hyrax4

class SingleUseLink < ActiveRecord::Base
  include LinkBehavior

  validate :expiration_date_cannot_be_in_the_past
  validate :cannot_be_destroyed

  alias_attribute :downloadKey, :download_key
  alias_attribute :itemId, :item_id

  after_initialize :set_defaults

  def create_for_path(path)
    self.class.create(item_id: item_id, path: path)
  end

  def expired?
    DateTime.current > expires
  end

  def to_param
    download_key
  end

  private

    def expiration_date_cannot_be_in_the_past
      errors.add(:expires, "can't be in the past") if expired? # TODO: convert to I18N
    end

    def cannot_be_destroyed
      errors[:base] << "Single Use Link has already been used" if destroyed? # TODO: convert to I18N
    end

    def set_defaults
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "user_id=#{user_id}",
      #                                        "" ] if ::Hyrax::SingleUseLinkService.single_use_link_service_debug_verbose
      return unless new_record?
      # self.expires ||= DateTime.current.advance( hours: 24 )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "::Hyrax::SingleUseLinkService.single_use_link_default_expiration_duration.class.name=#{::Hyrax::SingleUseLinkService.single_use_link_default_expiration_duration.class.name}",
      #                                        "::Hyrax::SingleUseLinkService.single_use_link_default_expiration_duration=#{::Hyrax::SingleUseLinkService.single_use_link_default_expiration_duration}",
      #                                        "::Hyrax::SingleUseLinkService.single_use_link_default_expiration_duration.parts=#{::Hyrax::SingleUseLinkService.single_use_link_default_expiration_duration.parts}",
      #                                        "" ] if ::Hyrax::SingleUseLinkService.single_use_link_service_debug_verbose
      self.expires ||= DateTime.current.advance( seconds: ::Hyrax::SingleUseLinkService.single_use_link_default_expiration_duration )
      self.download_key ||= LinkBehavior.generate_download_key
    end

end
