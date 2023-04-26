# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module WorkShowPresenterBehavior
      extend ActiveSupport::Concern

      included do
        delegated_methods = [
          :creator_name, :creator_orcid, :creator_display, :contributor_name, :contributor_orcid, :contributor_display
        ].freeze
        delegate(*delegated_methods, to: :solr_document)
      end

      def creator
        participants(:creator)
      end

      def contributor
        participants(:contributor)
      end

      private

        def participants(term)
          participants = JSON.parse(solr_document.public_send(term).first.presence || "[]")

          return if participants.blank?

          participants.pluck("#{term}_name")
        end
    end
  end
end
