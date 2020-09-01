
class SingleUseLink < ActiveRecord::Base

  validate :expiration_date_cannot_be_in_the_past
  validate :cannot_be_destroyed

  after_initialize :set_defaults

  def create_for_path(path)
    self.class.create(itemId: itemId, path: path)
  end

  def expired?
    DateTime.current > expires
  end

  def to_param
    downloadKey
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
      self.downloadKey ||= (Digest::SHA2.new << rand(1_000_000_000).to_s).to_s
    end

end
