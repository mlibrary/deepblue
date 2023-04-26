# frozen_string_literal: true
# hyrax-orcid

class OrcidIdentity < ApplicationRecord
  enum work_sync_preference: { sync_all: 0, sync_notify: 1, manual: 2 }

  belongs_to :user
  has_many :orcid_works, dependent: :destroy

  after_create :set_user_orcid_id

  validates :access_token, :token_type, :refresh_token, :expires_in, :scope, :orcid_id, presence: true
  validates_associated :user

  # Ensure we have an empty hash as a default value
  after_initialize do
    self.profile_sync_preference ||= {}
  end

  def self.profile_sync_preference
    %i[education employment funding peer_reviews works].freeze
  end

  def selected_sync_preferences
    profile_sync_preference.select { |_k, v| v == "1" }.keys
  end

  protected

    def set_user_orcid_id
      user.update(orcid: orcid_id)
    end
end
