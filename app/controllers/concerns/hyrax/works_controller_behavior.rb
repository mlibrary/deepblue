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
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "e=#{e}",
                                               "" ]
        begin
          # check with Fedora to see if the requested id was deleted
          id = params[:id]
          ActiveFedora::Base.find( id )
        rescue Ldp::Gone => gone
          # it was deleted
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "gone=#{gone.class} #{gone.message} at #{gone.backtrace[0]}",
                                                 "" ]
          # okay, since this looks like a deleted curation concern, we can check the provenance log
          # if admin, redirect to the provenance log controller
          if current_ability.admin?
            url = Rails.application.routes.url_helpers.url_for( only_path: true,
                                                                action: 'show',
                                                                controller: 'provenance_log',
                                                                id: id )
            return redirect_to( url, error: "#{id} was deleted." )
          end
        rescue ActiveFedora::ObjectNotFoundError => e2
          # nope, never existed
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "e2=#{e2.class} #{e2.message} at #{e2.backtrace[0]}",
                                                 "" ]
        end
        raise CanCan::AccessDenied
      end

      def document_not_found!
        doc = ::SolrDocument.find(params[:id])
        raise WorkflowAuthorizationException if doc.suppressed? && current_ability.can?(:read, doc)
        raise CanCan::AccessDenied.new(nil, :show)
      rescue Blacklight::Exceptions::RecordNotFound => e
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "e=#{e}",
                                               "" ]
        raise CanCan::AccessDenied
      end

  end

end
