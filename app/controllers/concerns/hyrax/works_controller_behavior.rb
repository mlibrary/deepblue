# frozen_string_literal: true
# monkey
# Reviewed: hyrax4

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/controllers/concerns/hyrax/works_controller_behavior.rb" )

module Hyrax

  module WorksControllerBehavior

    # begin monkey
    mattr_accessor :hyrax_works_controller_behavior_debug_verbose,
                   default: Rails.configuration.hyrax_works_controller_behavior_debug_verbose
    # end monkey

    private

      def curation_concern_from_search_results_debug_maybe
        search_params = params.deep_dup
        search_params.merge!( debug: 'all' )
        search_params.delete :page
        search_result_document(search_params)
      end

      def curation_concern_from_search_results
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " /
                           "Instead, use '#search_result_document'.")
        search_params = params.deep_dup
        search_params.delete :page
        search_result_document(search_params)
      end

      ##
      # Only returns unsuppressed documents the user has read access to
      #
      # @api public
      #
      # @param search_params [ActionController::Parameters] this should
      #   include an :id key, but based on implementation and use of the
      #   WorkSearchBuilder, it need not.
      #
      # @return [SolrDocument]
      #
      # @raise [WorkflowAuthorizationException] when the object is not
      #   found via the search builder's search logic BUT the object is
      #   suppressed AND the user can read it (Yeah, it's confusing but
      #   after a lot of debugging that's the logic)
      #
      # @raise [CanCan::AccessDenied] when the object is not found via
      #   the search builder's search logic BUT the object is not
      #   supressed OR not readable by the user (Yeah.)
      #
      # @note This is Jeremy, I have suspicions about the first line of
      #   this comment (eg, "Only return unsuppressed...").  The
      #   reason is that I've encounter situations in the specs
      #   where the document_list is empty but if I then query Solr
      #   for the object by ID, I get a document that is NOT
      #   suppressed AND can be read.  In other words, I believe
      #   there is more going on in the search_results method
      #   (e.g. a filter is being applied that is beyond what the
      #   comment indicates)
      #
      # @see #document_not_found!
      def search_result_document(search_params)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "search_params=#{search_params}",
                                               "" ] if hyrax_works_controller_behavior_debug_verbose
        _, document_list = search_results(search_params)
        return document_list.first unless document_list.empty?
        document_not_found!
      rescue Blacklight::Exceptions::RecordNotFound => e
        unless user_signed_in?
          # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
          #                                        ::Deepblue::LoggingHelper.called_from,
          #                                        "about to redirect - 01",
          #                                        "" ] if hyrax_works_controller_behavior_debug_verbose
          return redirect_to guest_user_message_url, alert: "unable to present requested work"
        end
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "e=#{e}",
        #                                        "" ] # + e.backtrace if hyrax_works_controller_behavior_debug_verbose
        begin
          # check with Fedora to see if the requested id was deleted
          id = params[:id]
          ::PersistHelper.find( id )
        rescue Ldp::Gone => gone
          # it was deleted
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "gone=#{gone.class} #{gone.message} at #{gone.backtrace[0]}",
                                                 "" ] if hyrax_works_controller_behavior_debug_verbose
          # okay, since this looks like a deleted curation concern, we can check the provenance log
          # if admin, redirect to the provenance log controller
          if current_ability.admin?
            # url = provenance_log_url
            # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
            #                                        ::Deepblue::LoggingHelper.called_from,
            #                                        "about to redirect to url=#{url}",
            #                                        "" ] if hyrax_works_controller_behavior_debug_verbose
            return redirect_to( provenance_log_url, alert: "\"#{id}\" was deleted." )
          end
        rescue Hyrax::ObjectNotFoundError => e2
          if current_ability.admin?
            # nope, never existed
            # url = provenance_log_url
            # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
            #                                        ::Deepblue::LoggingHelper.called_from,
            #                                        "e2=#{e2.class} #{e2.message} at #{e2.backtrace[0]}",
            #                                        "about to redirect - 02a - url=#{url}",
            #                                        "" ] if hyrax_works_controller_behavior_debug_verbose
            return redirect_to( provenance_log_url, alert: "\"#{id}\" not found." )
          end
        end
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "about to redirect - 02 - guest_user_message_url=#{guest_user_message_url}",
        #                                        "" ] if hyrax_works_controller_behavior_debug_verbose
        return redirect_to( guest_user_message_url, alert: "unable to present requested work" )
      end

      def document_not_found!
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params[:id]=#{params[:id]}",
                                               "" ] if hyrax_works_controller_behavior_debug_verbose
        doc = ::SolrDocument.find(params[:id])
        raise WorkflowAuthorizationException if doc.suppressed? && current_ability.can?(:read, doc)
        raise CanCan::AccessDenied.new(nil, :show)
      end

      def decide_layout
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "action_name=#{action_name}",
                                               "params[:anon_link_id].present?=#{params[:anon_link_id].present?}",
                                               "params[:link_id].present?=#{params[:link_id].present?}",
                                               "" ] if hyrax_works_controller_behavior_debug_verbose
        layout = if 'show' == action_name || params[:link_id].present? || params[:anon_link_id].present?
                   '1_column'
                 elsif 'single_use_link' == action_name
                   '1_column'
                 else
                   'dashboard'
                 end
        rv = File.join(theme, layout)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "" ] if hyrax_works_controller_behavior_debug_verbose
        return rv
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
