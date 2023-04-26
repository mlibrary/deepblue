# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module WorkHelper
      def primary_user?
        depositor == @identity.user
      end

      def depositor
        @_depositor ||= ::User.find_by_user_key @work.depositor
      end

      def depositor_description
        if depositor.orcid_identity?
          "#{depositor.orcid_identity.name} (#{depositor.orcid_identity.orcid_id})"
        else
          "#{depositor.name} (#{depositor.email})"
        end
      end

      def previously_published?
        orcid_work.put_code.present?
      end

      def orcid_work
        @_orcid_work ||= @identity.orcid_works.where(work_uuid: @work.id).first_or_initialize
      end
    end
  end
end
