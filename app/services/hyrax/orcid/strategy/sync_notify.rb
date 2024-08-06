# frozen_string_literal: true
# hyrax-orcid

# Sync the the users details if they are the priamry user, otherwise create a notification
module Hyrax
  module Orcid
    module Strategy
      class SyncNotify
        include Hyrax::Orcid::UrlHelper
        include Hyrax::Orcid::WorkHelper

        def initialize(work, identity)
          @work = work
          @identity = identity
        end

        def perform
          debug_verbose = ::Hyrax::OrcidIntegrationService.hyrax_orcid_strategy_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@work.id=#{@work.id}",
                                                 "@identity=#{@identity}",
                                                 "" ] if debug_verbose
          if primary_user?
            publish_work
          else
            notify
          end
        end

        protected

          def publish_work
            Hyrax::Orcid::Work::PublisherService.new(@work, @identity).publish
          end

          def notify
            depositor.send_message(@identity.user, message_body, message_subject)
          end

          def message_body
            params = {
              depositor_profile: depositor.orcid_identity? ? orcid_profile_uri(depositor.orcid_identity.orcid_id) : nil,
              depositor_description: depositor_description,
              profile_path: Hyrax::Engine.routes.url_helpers.dashboard_profile_path(@identity.user),
              work_title: @work.title.first,
              work_path: Rails.application.routes.url_helpers.send("hyrax_#{@work.class.name.underscore}_path", @work.id),
              approval_path: Rails.application.routes.url_helpers.orcid_works_publish_path(work_id: @work.id, orcid_id: @identity.orcid_id)
            }
            I18n.t!("hyrax.orcid.notify.notification.body", **params)
          end

          def message_subject
            I18n.t!("hyrax.orcid.notify.notification.subject", depositor_description: depositor_description)
          end
      end
    end
  end
end
