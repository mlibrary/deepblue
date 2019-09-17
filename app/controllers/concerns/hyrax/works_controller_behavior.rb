# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/controllers/concerns/hyrax/works_controller_behavior.rb" )

module Hyrax

  module WorksControllerBehavior

    private

      def curation_concern_from_search_results
        search_params = params
        search_params.delete :page
        search_result_document(search_params)
      end

      # Only returns unsuppressed documents the user has read access to
      def search_result_document(search_params)
        _, document_list = search_results(search_params)
        return document_list.first unless document_list.empty?
        document_not_found!
      rescue Blacklight::Exceptions::RecordNotFound => e
        unless user_signed_in?
          # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
          #                                        ::Deepblue::LoggingHelper.called_from,
          #                                        "about to redirect - 01",
          #                                        "" ]
          return redirect_to guest_user_message_url, alert: "unable to present requested work"
        end
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "e=#{e}",
        #                                        "" ] # + e.backtrace
        begin
          # check with Fedora to see if the requested id was deleted
          id = params[:id]
          ActiveFedora::Base.find( id )
        rescue Ldp::Gone => gone
          # it was deleted
          # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
          #                                        ::Deepblue::LoggingHelper.called_from,
          #                                        "gone=#{gone.class} #{gone.message} at #{gone.backtrace[0]}",
          #                                        "" ]
          # okay, since this looks like a deleted curation concern, we can check the provenance log
          # if admin, redirect to the provenance log controller
          if current_ability.admin?
            # url = provenance_log_url
            # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
            #                                        ::Deepblue::LoggingHelper.called_from,
            #                                        "about to redirect to url=#{url}",
            #                                        "" ]
            return redirect_to( provenance_log_url, alert: "\"#{id}\" was deleted." )
          end
        rescue ActiveFedora::ObjectNotFoundError => e2
          if current_ability.admin?
            # nope, never existed
            # url = provenance_log_url
            # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
            #                                        ::Deepblue::LoggingHelper.called_from,
            #                                        "e2=#{e2.class} #{e2.message} at #{e2.backtrace[0]}",
            #                                        "about to redirect - 02a - url=#{url}",
            #                                        "" ]
            return redirect_to( provenance_log_url, alert: "\"#{id}\" not found." )
          end
        end
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "about to redirect - 02 - guest_user_message_url=#{guest_user_message_url}",
        #                                        "" ]
        return redirect_to( guest_user_message_url, alert: "unable to present requested work" )
      end

      def document_not_found!
        doc = ::SolrDocument.find(params[:id])
        raise WorkflowAuthorizationException if doc.suppressed? && current_ability.can?(:read, doc)
        raise CanCan::AccessDenied.new(nil, :show)
      end

      def provenance_log_url
        id = params[:id]
        Rails.application.routes.url_helpers.url_for( only_path: true,
                                                      action: 'show',
                                                      controller: 'provenance_log',
                                                      id: id )
        # guest_user_message_url
      end

      def guest_user_message_url
        Rails.application.routes.url_helpers.url_for( only_path: true,
                                                      action: 'show',
                                                      controller: 'guest_user_message' )
      end

  end

end
