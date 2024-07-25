# frozen_string_literal: true
# hyrax-orcid

class OrcidIdentity < ApplicationRecord

  mattr_accessor :orcid_identity_debug_verbose, default: false

  serialize :profile_sync_preference, JSON

  enum work_sync_preference: { sync_all: 0, sync_notify: 1, manual: 2 }

  belongs_to :user
  has_many :orcid_works, dependent: :destroy

  validates :access_token, :token_type, :refresh_token, :expires_in, :scope, :orcid_id, presence: true
  validates_associated :user

  after_create :set_user_orcid_id

  before_save do
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "before_save",
                                           "" ] if orcid_identity_debug_verbose
    ensure_serialized
  end

  before_update do
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "before_update",
                                           "" ] if orcid_identity_debug_verbose
  end

  # Ensure we have an empty hash as a default value
  after_initialize do
    self.profile_sync_preference ||= {}
  end

  def self.profile_sync_preference
    %i[education employment funding peer_reviews works].freeze
  end

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

  def ensure_serialized
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "ensure_serialized",
                                           "Rails.env.production?=#{Rails.env.production?}",
                                           "profile_sync_preference.class.name=#{profile_sync_preference.class.name}",
                                           "profile_sync_preference=#{profile_sync_preference.pretty_inspect}",
                                           "" ] if orcid_identity_debug_verbose
  end

  protected

    def set_user_orcid_id
      user.update(orcid: orcid_id)
    end

end
