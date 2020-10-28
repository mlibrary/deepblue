# frozen_string_literal: true

module FindAndFixOrderedMembersBehavior

  FIND_AND_FIX_ALL_ORDERED_MEMBERS_CONTAINING_NILS_DEBUG_VERBOSE = true

  def find_and_fix_all_ordered_members_containing_nils( messages:, ids_fixed: [], test_mode: true, verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "messages=#{messages}",
                                           "ids_fixed=#{ids_fixed}",
                                           "" ] if FIND_AND_FIX_ALL_ORDERED_MEMBERS_CONTAINING_NILS_DEBUG_VERBOSE

    ::PersistHelper.all.each do |curation_concern|
      next unless curation_concern.respond_to? :ordered_members
      ordered_members = Array( curation_concern.ordered_members )
      next unless ordered_members.include? nil
      messages << "Compacting ordered_members for #{curation_concern.id}." if verbose
      ordered_members.compact
      curation_concern.ordered_members = ordered_members
      curation_concern.save!( validate: false )
      ids_fixed << curation_concern.id
    end

    messages << "Curation concern ids found and fixed: #{ids_fixed}" unless ids_fixed.empty?

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "verbose=#{verbose}",
                                           "test_mode=#{messages}",
                                           "messages=#{messages}",
                                           "ids_fixed=#{ids_fixed}",
                                           "" ] if FIND_AND_FIX_ALL_ORDERED_MEMBERS_CONTAINING_NILS_DEBUG_VERBOSE
  end

end
