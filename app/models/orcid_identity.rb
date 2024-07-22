# frozen_string_literal: true
# hyrax-orcid

class OrcidIdentity < ApplicationRecord

  # serialize :profile_sync_preference, JSON if Rails.env.production? # dev DB defines serialization natively, and this doesn't seem to work

  enum work_sync_preference: { sync_all: 0, sync_notify: 1, manual: 2 }

  belongs_to :user
  has_many :orcid_works, dependent: :destroy

  after_create :set_user_orcid_id

  validates :access_token, :token_type, :refresh_token, :expires_in, :scope, :orcid_id, presence: true
  validates_associated :user

  # Ensure we have an empty hash as a default value
  after_initialize do
    if Rails.env.production?
      self.profile_sync_preference ||= '{}'
    else
      self.profile_sync_preference ||= {}
    end
  end

  def self.profile_sync_preference
    %i[education employment funding peer_reviews works].freeze
  end

  # def profile_sync_preference=(value)
  #   if Rails.env.production?
  #     self.profile_sync_preference = do_serialize(value)
  #   else
  #     self.profile_sync_preference = value
  #   end
  # end

  def selected_sync_preferences
    psf = profile_sync_preference
    if ( psf.blank? )
      psf = {}
    elsif ( psf.is_a? String )
      psf = JSON.parse psf
    end
    rv = psf.select { |_k, v| v == "1" }.keys
    return rv
  end

  protected

    def set_user_orcid_id
      user.update(orcid: orcid_id)
    end

    def do_deserialize( value )
      if value.blank?
        {}
      elsif value.is_a? Hash
        value
      else
        deserialized_state = ActiveSupport::JSON.decode value
        return deserialized_state
      end
    rescue ActiveSupport::JSON.parse_error # rubocop:disable Lint/HandleExceptions
      {}
    end

    def do_serialize( value )
      if value.blank? || value.is_a?( String )
        value
      else
        ActiveSupport::JSON.encode( value ).to_s
      end
    rescue ActiveSupport::JSON.parse_error # rubocop:disable Lint/HandleExceptions
      {}
    end

end
