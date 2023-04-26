# frozen_string_literal: true
# hyrax-orcid

class OrcidWork < ApplicationRecord
  belongs_to :orcid_identity

  validates :work_uuid, :put_code, presence: true
  validates_associated :orcid_identity
end
