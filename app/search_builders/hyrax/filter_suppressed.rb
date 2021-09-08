# frozen_string_literal: true

module Hyrax

  # Injects a search builder filter to hide documents marked as suppressed
  module FilterSuppressed

    mattr_accessor :filter_suppressed_debug_verbose, default: false

    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:only_active_works]
    end

    def only_active_works(solr_parameters)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.class.name=#{self.class.name}",
                                             "solr_parameters[:fq]=#{solr_parameters[:fq]}",
                                             "" ] if filter_suppressed_debug_verbose
      if ( current_ability.admin? )
        solr_parameters[:fq] ||= []   
      elsif ( blacklight_params[:id] == nil )
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << '-suppressed_bsi:true'        
      elsif ( depositor? )
        solr_parameters[:fq] ||= []
      else
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << '-suppressed_bsi:true'
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.class.name=#{self.class.name}",
                                             "solr_parameters[:fq]=#{solr_parameters[:fq]}",
                                             "" ] if filter_suppressed_debug_verbose
    end

    def remove_draft_works(solr_parameters)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.class.name=#{self.class.name}",
                                             "solr_parameters[:fq]=#{solr_parameters[:fq]}",
                                             "" ] if filter_suppressed_debug_verbose
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << ::Deepblue::DraftAdminSetService.query_partial_to_remove_works_with_draft_admin_set
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "self.class.name=#{self.class.name}",
                                             "solr_parameters[:fq]=#{solr_parameters[:fq]}",
                                             "" ] if filter_suppressed_debug_verbose
    end


    private

      def current_work
        ::SolrDocument.find(blacklight_params[:id])
      end

      def depositor?
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "current_ability=#{current_ability}",
        #                                        "current_ability.current_user=#{current_ability.current_user}",
        #                                        "current_ability.current_user.user_key=#{current_ability.current_user.user_key}",
        #                                        "current_ability.current_user.guest?=#{current_ability.current_user.guest?}",
        #                                        "current_ability.current_user.new_record?=#{current_ability.current_user.new_record?}" ] if filter_suppressed_debug_verbose
        return false if current_ability.current_user.guest? || current_ability.current_user.new_record?
        # This is getting all the depositors to a collection.
        depositors = current_work["read_access_person_ssim"]

        return false if depositors.nil?
        
        found = false
        depositors.each do |depositor|
           if ( depositor == current_ability.current_user.user_key)
            found = true
          end
        end
        found
      end

  end

end
