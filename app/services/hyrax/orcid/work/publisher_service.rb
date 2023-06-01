# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module Work
      class PublisherService
        include Hyrax::Orcid::UrlHelper
        include Hyrax::Orcid::WorkHelper

        mattr_accessor :hyrax_orcid_publisher_service_debug_verbose,
                       default: ::Hyrax::OrcidIntegrationService.hyrax_orcid_publisher_service_debug_verbose

        def initialize(work, identity)
          @work = work
          @identity = identity
        end

        def publish
          debug_verbose = hyrax_orcid_publisher_service_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@work.id=#{@work.id}",
                                                 "@identity=#{@identity}",
                                                 "" ] if debug_verbose
          request_method = previously_published? ? :put : :post
          url = request_url
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "::Hyrax::OrcidIntegrationService.enable_work_syncronization=#{::Hyrax::OrcidIntegrationService.enable_work_syncronization}",
                                                 "request_url=#{url}",
                                                 "" ] if debug_verbose
          if ::Hyrax::OrcidIntegrationService.enable_work_syncronization
            @response = Faraday.send(request_method, url, xml, headers)

            if @response.success?
              update_identity
            else
              notify_contributor_error
            end
          end
        end

        def unpublish
          debug_verbose = hyrax_orcid_publisher_service_debug_verbose
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "@work.id=#{@work.id}",
                                                 "@identity=#{@identity}",
                                                 "" ] if debug_verbose
          url = request_url
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "::Hyrax::OrcidIntegrationService.enable_work_syncronization=#{::Hyrax::OrcidIntegrationService.enable_work_syncronization}",
                                                 "request_url=#{url}",
                                                 "" ] if debug_verbose

          if ::Hyrax::OrcidIntegrationService.enable_work_syncronization
            @response = Faraday.send(:delete, url, nil, headers)

            return unless @response.success?

            notify_unpublished
            orcid_work.destroy
          end
        end

        protected

          def xml
            reader_method = ::Hyrax::OrcidIntegrationService.bolognese[:reader_method]

            input = @work.attributes.merge(has_model: @work.has_model.first).to_json
            meta = Bolognese::Metadata.new(input: input, from: reader_method)

            # TODO: figure out how to get the correct types here
            # TODO: try and think of a better way to get the put_code into the xml writer
            meta.hyrax_orcid_xml("other", orcid_work.put_code)
          end

          def request_url
            orcid_api_uri(@identity.orcid_id, :work, orcid_work.put_code)
          end

          def headers
            {
              "authorization" => "Bearer #{@identity.access_token}",
              "Content-Type" => "application/vnd.orcid+xml"
            }
          end

          def notify_unpublished
            return if primary_user?

            subject = I18n.t("hyrax.orcid.unpublish.notification.subject", depositor_description: depositor_description)
            params = {
              depositor_profile: orcid_profile_uri(depositor.orcid_identity.orcid_id),
              depositor_description: depositor_description,
              work_title: @work.title.first
            }
            body = I18n.t("hyrax.orcid.unpublish.notification.body", params)

            depositor.send_message(@identity.user, body, subject)
          end

          def notify_contributor_error
            error = Hash.from_xml(@response.body)

            subject = I18n.t("hyrax.orcid.publish.error.notification.subject")
            params = {
              work_title: @work.title.first,
              short_error: error.dig("error", "user_message"),
              full_error: error.dig("error", "developer_message")
            }
            body = I18n.t("hyrax.orcid.publish.error.notification.body", params)

            depositor.send_message(@identity.user, body, subject)
          end

          def update_identity
            put_code = @response.headers.dig("location")&.split("/")&.last
            orcid_work.update(work_uuid: @work.id, put_code: put_code)
          end
      end
    end
  end
end
