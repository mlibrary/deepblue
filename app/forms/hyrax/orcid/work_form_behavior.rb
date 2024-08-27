# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module WorkFormBehavior
      extend ActiveSupport::Concern
      # hyrax-orcid - begin delete
      # class_methods do
      #   def build_permitted_params
      #     super.tap do |permitted_params|
      #       permitted_params << creator_fields
      #       permitted_params << contributor_fields
      #     end
      #   end
      #
      #   def creator_fields
      #     {
      #       creator: [:creator_name, :creator_orcid]
      #     }
      #   end
      #
      #   def contributor_fields
      #     {
      #       contributor: [:contributor_name, :contributor_orcid]
      #     }
      #   end
      # end
      # hyrax-orcid - end delete
    end
  end
end
