# frozen_string_literal: true
# Reviewed: heliotrope

class AptrustDeposit < ApplicationRecord
  include Filterable

  # scope :noid_like, ->(like) { where("noid like ?", "%#{like}%") }
  # scope :identifier_like, ->(like) { where("identifier like ?", "%#{like}%") }
end
