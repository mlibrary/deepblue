# frozen_string_literal: true
# Reviewed: heliotrope

module ApplicationHelper

  def self.is_local_host?
    Rails.env.development?
  end

end
